package app.nebula.iptv.player;

import android.app.Activity;
import android.content.Intent;
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

    @PluginMethod
    public void play(PluginCall call) {
        String url = call.getString("url");
        if (url == null || url.isEmpty()) {
            call.reject("URL ausente");
            return;
        }

        List<PlayerQueue.Item> queue = new ArrayList<>();
        JSArray raw = call.getArray("queue");
        if (raw != null) {
            for (int i = 0; i < raw.length(); i++) {
                JSONObject o = raw.optJSONObject(i);
                if (o == null) continue;
                queue.add(new PlayerQueue.Item(o.optString("id"), o.optString("title"), o.optString("url")));
            }
        }
        PlayerQueue.set(queue);

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
