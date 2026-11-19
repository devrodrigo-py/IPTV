package app.nebula.iptv;

import android.os.Bundle;
import android.webkit.WebSettings;
import app.nebula.iptv.player.NebulaPlayerPlugin;
import com.getcapacitor.BridgeActivity;

public class MainActivity extends BridgeActivity {
    @Override
    public void onCreate(Bundle savedInstanceState) {
        // Local plugins must be registered before the bridge starts.
        registerPlugin(NebulaPlayerPlugin.class);
        super.onCreate(savedInstanceState);
        // Honour the page's fixed-width viewport (1280 px TV layout) and scale it to the screen.
        WebSettings settings = getBridge().getWebView().getSettings();
        settings.setUseWideViewPort(true);
        settings.setLoadWithOverviewMode(true);
        settings.setSupportZoom(false);
        settings.setBuiltInZoomControls(false);
        settings.setMediaPlaybackRequiresUserGesture(false);
    }
}
