import android.os.SystemClock;
import android.view.InputDevice;
import android.view.InputEvent;
import android.view.MotionEvent;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.lang.reflect.Method;
import java.util.LinkedHashMap;
import java.util.Map;

/** Shell-only Android QA injector. Built separately; never shipped in the APK. */
public final class NullSwarmTouch {
    private final Map<Integer, float[]> pointers = new LinkedHashMap<>();
    private final Object manager;
    private final Method inject;
    private long downTime;

    private NullSwarmTouch() throws Exception {
        Class<?> type = Class.forName("android.hardware.input.InputManagerGlobal");
        manager = type.getMethod("getInstance").invoke(null);
        inject = type.getMethod("injectInputEvent", InputEvent.class, int.class);
    }

    private void event(int action) throws Exception {
        MotionEvent.PointerProperties[] properties = new MotionEvent.PointerProperties[pointers.size()];
        MotionEvent.PointerCoords[] coords = new MotionEvent.PointerCoords[pointers.size()];
        int i = 0;
        for (Map.Entry<Integer, float[]> item : pointers.entrySet()) {
            properties[i] = new MotionEvent.PointerProperties();
            properties[i].id = item.getKey();
            properties[i].toolType = MotionEvent.TOOL_TYPE_FINGER;
            coords[i] = new MotionEvent.PointerCoords();
            coords[i].x = item.getValue()[0];
            coords[i].y = item.getValue()[1];
            coords[i].pressure = 1;
            coords[i].size = 1;
            i++;
        }
        MotionEvent event = MotionEvent.obtain(downTime, SystemClock.uptimeMillis(), action,
                pointers.size(), properties, coords, 0, 0, 1, 1, 0, 0, InputDevice.SOURCE_TOUCHSCREEN, 0);
        try {
            if (!Boolean.TRUE.equals(inject.invoke(manager, event, 2))) {
                throw new IllegalStateException("Android rejected touch injection");
            }
        } finally {
            event.recycle();
        }
    }

    private void command(String line) throws Exception {
        String[] parts = line.trim().split("\\s+");
        if (parts.length != 4) throw new IllegalArgumentException("Expected: down|move|up id x y");
        int id = Integer.parseInt(parts[1]);
        if (id < 0 || id > 31) throw new IllegalArgumentException("Pointer ID outside Android range");
        float[] xy = {Float.parseFloat(parts[2]), Float.parseFloat(parts[3])};
        if (parts[0].equals("down")) {
            if (pointers.containsKey(id) || pointers.size() >= 2) throw new IllegalStateException("Invalid new pointer");
            if (pointers.isEmpty()) downTime = SystemClock.uptimeMillis();
            pointers.put(id, xy);
            event(pointers.size() == 1 ? MotionEvent.ACTION_DOWN : MotionEvent.ACTION_POINTER_DOWN
                    | ((pointers.size() - 1) << MotionEvent.ACTION_POINTER_INDEX_SHIFT));
        } else {
            if (!pointers.containsKey(id)) throw new IllegalStateException("Pointer is not held");
            pointers.put(id, xy);
            if (parts[0].equals("move")) {
                event(MotionEvent.ACTION_MOVE);
            } else if (parts[0].equals("up")) {
                int index = 0;
                for (Integer key : pointers.keySet()) {
                    if (key == id) break;
                    index++;
                }
                event(pointers.size() == 1 ? MotionEvent.ACTION_UP : MotionEvent.ACTION_POINTER_UP
                        | (index << MotionEvent.ACTION_POINTER_INDEX_SHIFT));
                pointers.remove(id);
            } else throw new IllegalArgumentException("Unknown command");
        }
        System.out.println("ACK " + line);
        System.out.flush();
    }

    public static void main(String[] args) throws Exception {
        NullSwarmTouch touch = new NullSwarmTouch();
        System.out.println("READY");
        System.out.flush();
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(System.in))) {
            String line;
            while ((line = reader.readLine()) != null) {
                if (line.equals("quit")) break;
                touch.command(line);
            }
        } finally {
            if (!touch.pointers.isEmpty()) touch.event(MotionEvent.ACTION_CANCEL);
        }
    }
}
