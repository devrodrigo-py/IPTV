package app.nebula.iptv.player;

import java.util.ArrayList;
import java.util.List;

/**
 * Channel list for zapping inside the native player. Kept in memory instead of
 * Intent extras because a few thousand channels exceed the 1 MB Binder limit.
 */
public final class PlayerQueue {
    public static final class Item {
        public final String id;
        public final String title;
        public final String url;
        public final String subtitle;
        /** Channel number shown to the user (grid order); 0 when unknown. */
        public final int number;

        public Item(String id, String title, String url, String subtitle, int number) {
            this.id = id;
            this.title = title;
            this.url = url;
            this.subtitle = subtitle;
            this.number = number;
        }
    }

    private static List<Item> items = new ArrayList<>();

    private PlayerQueue() {}

    public static synchronized void set(List<Item> list) {
        items = list != null ? list : new ArrayList<Item>();
    }

    public static synchronized List<Item> get() {
        return items;
    }
}
