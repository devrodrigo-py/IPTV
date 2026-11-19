package app.nebula.iptv.player;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.KeyEvent;
import android.view.View;
import android.view.WindowManager;
import android.widget.Button;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.annotation.OptIn;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.view.WindowCompat;
import androidx.core.view.WindowInsetsCompat;
import androidx.core.view.WindowInsetsControllerCompat;
import androidx.media3.common.C;
import androidx.media3.common.MediaItem;
import androidx.media3.common.MimeTypes;
import androidx.media3.common.PlaybackException;
import androidx.media3.common.Player;
import androidx.media3.common.util.UnstableApi;
import androidx.media3.datasource.DefaultDataSource;
import androidx.media3.datasource.DefaultHttpDataSource;
import androidx.media3.exoplayer.DefaultLoadControl;
import androidx.media3.exoplayer.DefaultRenderersFactory;
import androidx.media3.exoplayer.ExoPlayer;
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory;
import androidx.media3.exoplayer.trackselection.DefaultTrackSelector;
import androidx.media3.extractor.DefaultExtractorsFactory;
import androidx.media3.extractor.ts.DefaultTsPayloadReaderFactory;
import androidx.media3.ui.PlayerView;
import app.nebula.iptv.R;
import java.util.List;
import java.util.Locale;

/**
 * Full-screen Media3/ExoPlayer for live TV, movies and episodes.
 *
 * Why native: the Android TV / Fire TV WebView cannot play MPEG-TS, usually
 * lacks HEVC and AC3/EAC3, and has no hardware-tunnelled audio passthrough.
 * ExoPlayer handles all of these and exposes audio/subtitle track menus.
 *
 * Remote control:
 *  - Live: CH+/CH- (and D-pad up/down while the controls are hidden) change
 *    channel; number keys jump to a channel; OK shows the controls.
 *  - On demand: D-pad left/right seek 10 s while the controls are hidden.
 *  - Back hides the controls first, then closes the player.
 */
@OptIn(markerClass = UnstableApi.class)
public class PlayerActivity extends AppCompatActivity {
    public static final String EXTRA_URL = "url";
    public static final String EXTRA_TITLE = "title";
    public static final String EXTRA_SUBTITLE = "subtitle";
    public static final String EXTRA_IS_LIVE = "isLive";
    public static final String EXTRA_START_MS = "startMs";
    public static final String EXTRA_QUEUE_INDEX = "queueIndex";
    public static final String EXTRA_USER_AGENT = "userAgent";
    public static final String EXTRA_BUFFER_MODE = "bufferMode";
    public static final String EXTRA_NEXT_TITLE = "nextTitle";

    public static final String RESULT_POSITION_MS = "positionMs";
    public static final String RESULT_DURATION_MS = "durationMs";
    public static final String RESULT_COMPLETED = "completed";
    public static final String RESULT_QUEUE_INDEX = "queueIndex";
    public static final String RESULT_PLAY_NEXT = "playNext";
    public static final String RESULT_ERROR = "error";

    private static final int MAX_RETRIES = 6;
    private static final long NEXT_EPISODE_LEAD_MS = 25_000;
    private static final long INFO_VISIBLE_MS = 5_000;
    private static final String DEFAULT_USER_AGENT = "NebulaIPTV/3.0 (Linux; Android TV) ExoPlayer";

    private final Handler handler = new Handler(Looper.getMainLooper());

    private ExoPlayer player;
    private PlayerView playerView;
    private TextView infoView;
    private TextView statusView;
    private Button nextButton;

    private boolean isLive;
    private String title;
    private String subtitle;
    private String nextTitle;
    private List<PlayerQueue.Item> queue;
    private int queueIndex;
    private int retries;
    private boolean finished;
    private boolean nextDismissed;
    private String lastError;
    private final StringBuilder digits = new StringBuilder();

    private final Runnable hideInfo = () -> infoView.setVisibility(View.GONE);
    private final Runnable commitDigits = this::jumpToTypedChannel;
    private final Runnable tick = new Runnable() {
        @Override
        public void run() {
            updateNextButton();
            handler.postDelayed(this, 1000);
        }
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_player);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        enterImmersive();

        playerView = findViewById(R.id.player_view);
        infoView = findViewById(R.id.player_info);
        statusView = findViewById(R.id.player_status);
        nextButton = findViewById(R.id.next_button);

        Intent in = getIntent();
        isLive = in.getBooleanExtra(EXTRA_IS_LIVE, false);
        title = in.getStringExtra(EXTRA_TITLE);
        subtitle = in.getStringExtra(EXTRA_SUBTITLE);
        nextTitle = in.getStringExtra(EXTRA_NEXT_TITLE);
        queue = PlayerQueue.get();
        queueIndex = in.getIntExtra(EXTRA_QUEUE_INDEX, -1);

        player = buildPlayer(in.getStringExtra(EXTRA_USER_AGENT), in.getStringExtra(EXTRA_BUFFER_MODE));
        playerView.setPlayer(player);
        playerView.setShowSubtitleButton(true);
        playerView.setShowNextButton(false);
        playerView.setShowPreviousButton(false);
        playerView.setControllerShowTimeoutMs(4000);
        playerView.setKeepScreenOn(true);
        if (isLive) {
            // Live streams have no meaningful timeline to scrub.
            playerView.setShowFastForwardButton(false);
            playerView.setShowRewindButton(false);
        }

        nextButton.setOnClickListener(v -> finishWithResult(false, true));

        player.addListener(new Player.Listener() {
            @Override
            public void onPlaybackStateChanged(int state) {
                if (state == Player.STATE_READY) {
                    retries = 0;
                    statusView.setVisibility(View.GONE);
                } else if (state == Player.STATE_ENDED && !isLive) {
                    finishWithResult(true, false);
                }
            }

            @Override
            public void onPlayerError(@NonNull PlaybackException error) {
                handleError(error);
            }
        });

        String url = in.getStringExtra(EXTRA_URL);
        long startMs = in.getLongExtra(EXTRA_START_MS, 0);
        load(url, startMs);
        showInfo(title, subtitle);
        handler.post(tick);
    }

    private ExoPlayer buildPlayer(String userAgent, String bufferMode) {
        DefaultHttpDataSource.Factory http = new DefaultHttpDataSource.Factory()
                .setUserAgent(userAgent == null || userAgent.isEmpty() ? DEFAULT_USER_AGENT : userAgent)
                .setAllowCrossProtocolRedirects(true)
                .setConnectTimeoutMs(15_000)
                .setReadTimeoutMs(20_000);

        // Many IPTV TS streams start without an IDR frame; this starts video sooner.
        DefaultExtractorsFactory extractors = new DefaultExtractorsFactory()
                .setTsExtractorFlags(DefaultTsPayloadReaderFactory.FLAG_ALLOW_NON_IDR_KEYFRAMES)
                .setConstantBitrateSeekingEnabled(true);

        DefaultMediaSourceFactory sources = new DefaultMediaSourceFactory(new DefaultDataSource.Factory(this, http), extractors);

        int minBuffer;
        int maxBuffer;
        int startBuffer;
        if ("low".equals(bufferMode)) {
            minBuffer = 4_000;
            maxBuffer = 15_000;
            startBuffer = 1_000;
        } else if ("high".equals(bufferMode)) {
            minBuffer = 30_000;
            maxBuffer = 90_000;
            startBuffer = 3_000;
        } else {
            minBuffer = 15_000;
            maxBuffer = 50_000;
            startBuffer = 2_000;
        }
        DefaultLoadControl load = new DefaultLoadControl.Builder()
                .setBufferDurationsMs(minBuffer, maxBuffer, startBuffer, startBuffer * 2)
                .build();

        // Fall back to another decoder (e.g. software) when the hardware one refuses a stream.
        DefaultRenderersFactory renderers = new DefaultRenderersFactory(this)
                .setEnableDecoderFallback(true)
                .setExtensionRendererMode(DefaultRenderersFactory.EXTENSION_RENDERER_MODE_PREFER);

        DefaultTrackSelector selector = new DefaultTrackSelector(this);
        String lang = Locale.getDefault().getLanguage();
        selector.setParameters(selector.buildUponParameters()
                .setPreferredAudioLanguage(lang)
                .setPreferredTextLanguage(lang));

        return new ExoPlayer.Builder(this)
                .setRenderersFactory(renderers)
                .setMediaSourceFactory(sources)
                .setLoadControl(load)
                .setTrackSelector(selector)
                .setSeekBackIncrementMs(10_000)
                .setSeekForwardIncrementMs(10_000)
                .build();
    }

    private void load(String url, long startMs) {
        if (url == null || url.isEmpty()) {
            lastError = "URL vazia";
            finishWithResult(false, false);
            return;
        }
        MediaItem.Builder item = new MediaItem.Builder().setUri(Uri.parse(url));
        String path = Uri.parse(url).getPath();
        String lower = path == null ? "" : path.toLowerCase(Locale.ROOT);
        if (lower.endsWith(".m3u8") || lower.endsWith(".m3u") || lower.contains("/hls/")) {
            item.setMimeType(MimeTypes.APPLICATION_M3U8);
        } else if (lower.endsWith(".mpd")) {
            item.setMimeType(MimeTypes.APPLICATION_MPD);
        }
        // Anything else (.ts, .mp4, .mkv, extension-less Xtream URLs) is sniffed
        // by the progressive extractors.
        player.setMediaItem(item.build(), Math.max(0, startMs));
        player.prepare();
        player.setPlayWhenReady(true);
    }

    private void handleError(PlaybackException error) {
        if (error.errorCode == PlaybackException.ERROR_CODE_BEHIND_LIVE_WINDOW) {
            player.seekToDefaultPosition();
            player.prepare();
            return;
        }
        lastError = error.getErrorCodeName();
        // Decoder/format problems do not go away by reconnecting: say so at once.
        boolean decoderProblem = error.errorCode >= PlaybackException.ERROR_CODE_DECODER_INIT_FAILED
                && error.errorCode <= PlaybackException.ERROR_CODE_DECODING_RESOURCES_RECLAIMED;
        boolean formatProblem = error.errorCode == PlaybackException.ERROR_CODE_PARSING_CONTAINER_UNSUPPORTED
                || error.errorCode == PlaybackException.ERROR_CODE_PARSING_MANIFEST_UNSUPPORTED
                || error.errorCode == PlaybackException.ERROR_CODE_DECODING_FORMAT_UNSUPPORTED
                || error.errorCode == PlaybackException.ERROR_CODE_DECODING_FORMAT_EXCEEDS_CAPABILITIES;
        if (!decoderProblem && !formatProblem && retries < MAX_RETRIES) {
            long delay = Math.min(15_000L, 1000L << retries);
            retries++;
            statusView.setText(String.format(Locale.ROOT, "Reconectando (%d/%d)…", retries, MAX_RETRIES));
            statusView.setVisibility(View.VISIBLE);
            final long position = isLive ? C.TIME_UNSET : player.getCurrentPosition();
            handler.postDelayed(() -> {
                if (finished) return;
                if (position != C.TIME_UNSET) player.seekTo(position);
                player.prepare();
                player.setPlayWhenReady(true);
            }, delay);
        } else {
            statusView.setText("Não foi possível reproduzir este conteúdo.\n" + describe(error) + "\nPressione Voltar.");
            statusView.setVisibility(View.VISIBLE);
        }
    }

    private static String describe(PlaybackException error) {
        switch (error.errorCode) {
            case PlaybackException.ERROR_CODE_IO_BAD_HTTP_STATUS:
                return "O servidor recusou a conexão (assinatura expirada ou limite de telas).";
            case PlaybackException.ERROR_CODE_IO_NETWORK_CONNECTION_FAILED:
            case PlaybackException.ERROR_CODE_IO_NETWORK_CONNECTION_TIMEOUT:
                return "Sem conexão com o servidor.";
            case PlaybackException.ERROR_CODE_DECODER_INIT_FAILED:
            case PlaybackException.ERROR_CODE_DECODER_QUERY_FAILED:
            case PlaybackException.ERROR_CODE_DECODING_FAILED:
            case PlaybackException.ERROR_CODE_DECODING_FORMAT_UNSUPPORTED:
            case PlaybackException.ERROR_CODE_DECODING_FORMAT_EXCEEDS_CAPABILITIES:
                return "Este aparelho não consegue decodificar o vídeo deste conteúdo (formato ou resolução).";
            case PlaybackException.ERROR_CODE_PARSING_CONTAINER_UNSUPPORTED:
                return "Formato de arquivo não suportado.";
            default:
                return error.getErrorCodeName();
        }
    }

    // ------------------------------------------------------------------ zapping

    private boolean canZap() {
        return isLive && queue != null && queue.size() > 1 && queueIndex >= 0;
    }

    private void zap(int offset) {
        if (!canZap()) return;
        int size = queue.size();
        switchTo(((queueIndex + offset) % size + size) % size);
    }

    private void switchTo(int index) {
        if (queue == null || index < 0 || index >= queue.size()) return;
        queueIndex = index;
        PlayerQueue.Item item = queue.get(index);
        title = item.title;
        subtitle = item.subtitle;
        retries = 0;
        load(item.url, 0);
        int shown = item.number > 0 ? item.number : index + 1;
        showInfo(String.format(Locale.ROOT, "%02d  %s", shown, item.title), item.subtitle);
    }

    private void jumpToTypedChannel() {
        if (digits.length() == 0) return;
        try {
            int number = Integer.parseInt(digits.toString());
            // Jump to the channel with that grid number; fall back to the list position.
            int target = -1;
            for (int i = 0; i < queue.size(); i++) {
                if (queue.get(i).number == number) {
                    target = i;
                    break;
                }
            }
            if (target == -1 && number >= 1 && number <= queue.size() && queue.get(0).number == 0) target = number - 1;
            if (target >= 0) switchTo(target);
            else showInfo("Canal " + number + " não está nesta categoria", null);
        } catch (NumberFormatException ignored) {
            // Too many digits: ignore.
        }
        digits.setLength(0);
    }

    private void showInfo(String line1, String line2) {
        String text = line2 == null || line2.isEmpty() ? line1 : line1 + "\n" + line2;
        if (text == null || text.isEmpty()) return;
        infoView.setText(text);
        infoView.setVisibility(View.VISIBLE);
        handler.removeCallbacks(hideInfo);
        handler.postDelayed(hideInfo, INFO_VISIBLE_MS);
    }

    // ------------------------------------------------------------------ next episode

    private void updateNextButton() {
        if (player == null || isLive || nextTitle == null || nextTitle.isEmpty() || nextDismissed) {
            nextButton.setVisibility(View.GONE);
            return;
        }
        long duration = player.getDuration();
        long position = player.getCurrentPosition();
        boolean show = duration != C.TIME_UNSET && duration > 0 && duration - position <= NEXT_EPISODE_LEAD_MS;
        if (show && nextButton.getVisibility() != View.VISIBLE) {
            nextButton.setText("Próximo: " + nextTitle);
            nextButton.setVisibility(View.VISIBLE);
            nextButton.requestFocus();
        } else if (!show) {
            nextButton.setVisibility(View.GONE);
        }
    }

    // ------------------------------------------------------------------ keys

    @Override
    public boolean dispatchKeyEvent(KeyEvent event) {
        if (event.getAction() != KeyEvent.ACTION_DOWN) return super.dispatchKeyEvent(event);
        int code = event.getKeyCode();
        boolean controlsVisible = playerView.isControllerFullyVisible();

        if (code == KeyEvent.KEYCODE_BACK || code == KeyEvent.KEYCODE_ESCAPE) {
            if (nextButton.getVisibility() == View.VISIBLE) {
                nextDismissed = true;
                nextButton.setVisibility(View.GONE);
                return true;
            }
            if (controlsVisible) {
                playerView.hideController();
                return true;
            }
            finishWithResult(false, false);
            return true;
        }

        if (isLive) {
            if (code == KeyEvent.KEYCODE_CHANNEL_UP || code == KeyEvent.KEYCODE_PAGE_UP || (!controlsVisible && code == KeyEvent.KEYCODE_DPAD_UP)) {
                zap(1);
                return true;
            }
            if (code == KeyEvent.KEYCODE_CHANNEL_DOWN || code == KeyEvent.KEYCODE_PAGE_DOWN || (!controlsVisible && code == KeyEvent.KEYCODE_DPAD_DOWN)) {
                zap(-1);
                return true;
            }
            if (code >= KeyEvent.KEYCODE_0 && code <= KeyEvent.KEYCODE_9 && canZap()) {
                if (digits.length() < 5) digits.append((char) ('0' + (code - KeyEvent.KEYCODE_0)));
                showInfo(digits.toString(), null);
                handler.removeCallbacks(commitDigits);
                handler.postDelayed(commitDigits, 1500);
                return true;
            }
            if (!controlsVisible && (code == KeyEvent.KEYCODE_INFO || code == KeyEvent.KEYCODE_GUIDE)) {
                showInfo(title, subtitle);
                return true;
            }
        } else if (!controlsVisible || focusOnSeekTarget()) {
            // Left/right keep seeking while focus is on play/pause or the time bar
            // (streaming-app behaviour); on the other buttons they move focus.
            if (code == KeyEvent.KEYCODE_DPAD_RIGHT || code == KeyEvent.KEYCODE_MEDIA_FAST_FORWARD) {
                player.seekForward();
                playerView.showController();
                return true;
            }
            if (code == KeyEvent.KEYCODE_DPAD_LEFT || code == KeyEvent.KEYCODE_MEDIA_REWIND) {
                player.seekBack();
                playerView.showController();
                return true;
            }
        }
        return super.dispatchKeyEvent(event);
    }

    private boolean focusOnSeekTarget() {
        View f = getCurrentFocus();
        if (f == null) return true;
        int id = f.getId();
        return id == View.NO_ID
                || id == R.id.player_view
                || id == androidx.media3.ui.R.id.exo_play_pause
                || id == androidx.media3.ui.R.id.exo_progress;
    }

    // ------------------------------------------------------------------ lifecycle

    private void finishWithResult(boolean completed, boolean playNext) {
        if (finished) return;
        finished = true;
        Intent data = new Intent();
        long duration = player != null ? player.getDuration() : C.TIME_UNSET;
        long position = player != null ? player.getCurrentPosition() : 0;
        data.putExtra(RESULT_POSITION_MS, completed && duration != C.TIME_UNSET ? duration : Math.max(0, position));
        data.putExtra(RESULT_DURATION_MS, duration == C.TIME_UNSET ? 0L : duration);
        data.putExtra(RESULT_COMPLETED, completed);
        data.putExtra(RESULT_QUEUE_INDEX, Math.max(0, queueIndex));
        data.putExtra(RESULT_PLAY_NEXT, playNext);
        if (lastError != null) data.putExtra(RESULT_ERROR, lastError);
        setResult(RESULT_OK, data);
        finish();
    }

    private void enterImmersive() {
        WindowCompat.setDecorFitsSystemWindows(getWindow(), false);
        WindowInsetsControllerCompat c = WindowCompat.getInsetsController(getWindow(), getWindow().getDecorView());
        c.hide(WindowInsetsCompat.Type.systemBars());
        c.setSystemBarsBehavior(WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE);
    }

    @Override
    protected void onPause() {
        super.onPause();
        // Home button / screensaver: stop decoding and the network stream.
        if (player != null && !finished) player.pause();
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (player != null && !finished) player.setPlayWhenReady(true);
    }

    @Override
    protected void onDestroy() {
        handler.removeCallbacksAndMessages(null);
        if (player != null) {
            player.release();
            player = null;
        }
        super.onDestroy();
    }
}
