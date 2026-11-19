package app.nebula.iptv;

import android.os.Bundle;
import app.nebula.iptv.player.NebulaPlayerPlugin;
import com.getcapacitor.BridgeActivity;

public class MainActivity extends BridgeActivity {
    @Override
    public void onCreate(Bundle savedInstanceState) {
        // Local plugins must be registered before the bridge starts.
        registerPlugin(NebulaPlayerPlugin.class);
        super.onCreate(savedInstanceState);
    }
}
