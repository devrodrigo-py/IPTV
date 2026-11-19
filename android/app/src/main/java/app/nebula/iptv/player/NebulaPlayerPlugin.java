package app.nebula.iptv.player;

import android.app.Activity;
import android.content.Intent;
import android.speech.RecognizerIntent;
import java.util.Locale;
import androidx.activity.result.ActivityResult;
import com.getcapacitor.JSArray;
import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.ActivityCallback;
import com.getcapacitor.annotation.CapacitorPlugin;
import java.util.ArrayList;
import java.util.List;
import org.json.JSONObject;

/**
 * JavaScript bridge: NebulaPlayer.play(options) opens {@link PlayerActivity} and
 * resolves with the position, duration and how playback ended.
 */
@CapacitorPlugin(name = "NebulaPlayer")
public class NebulaPlayerPlugin extends Plugin {

    /**
     * Zapping list for the next play(). Sent separately because Capacitor keeps
     * the play() call's options in the activity's saved state while the player
     * is open; a large channel list there exceeds Android's ~1 MB Binder limit
     * (TransactionTooLargeException) and crashes the app.
     */
    @PluginMethod
    public void setQueue(PluginCall call) {
        List<PlayerQueue.Item> queue = new ArrayList<>();
        JSArray raw = call.getArray("queue");
        if (raw != null) {
            for (int i = 0; i < raw.length(); i++) {
                JSONObject o = raw.optJSONObject(i);
                if (o == null) continue;
                queue.add(new PlayerQueue.Item(o.optString("id"), o.optString("title"), o.optString("url"), o.optString("subtitle", ""), o.optInt("number", 0)));
            }
        }
        PlayerQueue.set(queue);
        call.resolve();
    }

    @PluginMethod
    public void play(PluginCall call) {
        String url = call.getString("url");
        if (url == null || url.isEmpty()) {
            call.reject("URL ausente");
            return;
        }

        Intent intent = new Intent(getContext(), PlayerActivity.class);
        intent.putExtra(PlayerActivity.EXTRA_URL, url);
        intent.putExtra(PlayerActivity.EXTRA_TITLE, call.getString("title", ""));
        intent.putExtra(PlayerActivity.EXTRA_SUBTITLE, call.getString("subtitle", ""));
        intent.putExtra(PlayerActivity.EXTRA_IS_LIVE, Boolean.TRUE.equals(call.getBoolean("isLive", false)));
        Double start = call.getDouble("startPositionMs");
        intent.putExtra(PlayerActivity.EXTRA_START_MS, start != null ? start.longValue() : 0L);
        Integer index = call.getInt("queueIndex");
        intent.putExtra(PlayerActivity.EXTRA_QUEUE_INDEX, index != null ? index : -1);
        intent.putExtra(PlayerActivity.EXTRA_USER_AGENT, call.getString("userAgent", ""));
        intent.putExtra(PlayerActivity.EXTRA_BUFFER_MODE, call.getString("bufferMode", "balanced"));
        intent.putExtra(PlayerActivity.EXTRA_NEXT_TITLE, call.getString("nextTitle", ""));

        startActivityForResult(call, intent, "onPlayerClosed");
    }

    /** True when the device offers speech recognition to apps (Google TV yes, most Fire TV no). */
    @PluginMethod
    public void isVoiceSearchAvailable(PluginCall call) {
        JSObject ret = new JSObject();
        ret.put("available", speechIntent().resolveActivity(getContext().getPackageManager()) != null);
        call.resolve(ret);
    }

    @PluginMethod
    public void voiceSearch(PluginCall call) {
        Intent intent = speechIntent();
        if (intent.resolveActivity(getContext().getPackageManager()) == null) {
            call.reject("Busca por voz indisponível neste aparelho", "UNAVAILABLE");
            return;
        }
        startActivityForResult(call, intent, "onVoiceResult");
    }

    private Intent speechIntent() {
        Intent intent = new Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH);
        intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM);
        intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE, Locale.getDefault().toLanguageTag());
        intent.putExtra(RecognizerIntent.EXTRA_PROMPT, "Diga o nome de um filme, série ou canal");
        intent.putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1);
        return intent;
    }

    @ActivityCallback
    private void onVoiceResult(PluginCall call, ActivityResult result) {
        if (call == null) return;
        JSObject ret = new JSObject();
        String text = "";
        Intent data = result.getData();
        if (result.getResultCode() == Activity.RESULT_OK && data != null) {
            java.util.ArrayList<String> matches = data.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS);
            if (matches != null && !matches.isEmpty()) text = matches.get(0);
        }
        ret.put("text", text);
        call.resolve(ret);
    }

    @ActivityCallback
    private void onPlayerClosed(PluginCall call, ActivityResult result) {
        if (call == null) return;
        Intent data = result.getData();
        JSObject ret = new JSObject();
        if (data == null) {
            ret.put("positionMs", 0);
            ret.put("durationMs", 0);
            ret.put("completed", false);
            ret.put("queueIndex", call.getInt("queueIndex", 0));
            ret.put("playNext", false);
        } else {
            ret.put("positionMs", data.getLongExtra(PlayerActivity.RESULT_POSITION_MS, 0));
            ret.put("durationMs", data.getLongExtra(PlayerActivity.RESULT_DURATION_MS, 0));
            ret.put("completed", data.getBooleanExtra(PlayerActivity.RESULT_COMPLETED, false));
            ret.put("queueIndex", data.getIntExtra(PlayerActivity.RESULT_QUEUE_INDEX, 0));
            ret.put("playNext", data.getBooleanExtra(PlayerActivity.RESULT_PLAY_NEXT, false));
            String error = data.getStringExtra(PlayerActivity.RESULT_ERROR);
            if (error != null) ret.put("error", error);
        }
        // Activity.RESULT_CANCELED (e.g. the system killed the player) still resolves.
        if (result.getResultCode() != Activity.RESULT_OK && data == null) {
            ret.put("completed", false);
        }
        call.resolve(ret);
    }
}
