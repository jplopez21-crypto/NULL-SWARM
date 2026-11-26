/* NULL//SWARM diagnostic harness. Controlled fields; no real EGL/GPU is invoked. */
package org.godotengine.godot.gl;

import java.lang.ref.WeakReference;
import java.lang.reflect.Constructor;
import java.lang.reflect.Field;
import java.lang.reflect.Method;

public final class SurfaceLatchHarness {
    static final Class<?> THREAD;
    static final Object MANAGER;
    static {
        try {
            THREAD = Class.forName("org.godotengine.godot.gl.GLSurfaceView$GLThread");
            Field manager = GLSurfaceView.class.getDeclaredField("sGLThreadManager");
            manager.setAccessible(true);
            MANAGER = manager.get(null);
        } catch (Exception error) { throw new RuntimeException(error); }
    }
    static Object thread() throws Exception {
        Constructor<?> constructor = THREAD.getDeclaredConstructor(WeakReference.class);
        constructor.setAccessible(true);
        Object value = constructor.newInstance(new WeakReference<GLSurfaceView>(null));
        set(value, "mWidth", 720); set(value, "mHeight", 1280);
        return value;
    }
    static void set(Object thread, String name, Object value) throws Exception {
        Field field = THREAD.getDeclaredField(name); field.setAccessible(true); field.set(thread, value);
    }
    static Object get(Object thread, String name) throws Exception {
        Field field = THREAD.getDeclaredField(name); field.setAccessible(true); return field.get(thread);
    }
    static Object invoke(Object thread, String name) throws Exception {
        Method method = THREAD.getDeclaredMethod(name); method.setAccessible(true); return method.invoke(thread);
    }
    static void require(boolean value, String message) {
        if (!value) throw new AssertionError(message);
    }
    public static void main(String[] args) throws Exception {
        boolean latched = args.length == 1 && args[0].equals("latched");
        Object value = thread();
        invoke(value, "surfaceCreated"); invoke(value, "surfaceDestroyed"); invoke(value, "surfaceCreated");
        set(value, "mSurfaceIsBad", true); // Old in-flight swap fails after new surface callback.
        require(!(Boolean)invoke(value, "readyToDraw"), "stale bad flag must initially prevent drawing");
        if (latched) {
            set(value, "mHaveEglContext", true);
            synchronized (MANAGER) { invoke(value, "consumePendingSurfaceChangeLocked"); }
            require((Boolean)invoke(value, "readyToDraw"), "latched lifecycle edge must allow surface recreation");
            require((Boolean)get(value, "mHaveEglContext"), "EGL context must be preserved");
            require(!(Boolean)get(value, "mSurfaceRecreatePending"), "consumed edge must clear");
            invoke(value, "surfaceDestroyed");
            synchronized (MANAGER) { invoke(value, "consumePendingSurfaceChangeLocked"); }
            require(!(Boolean)invoke(value, "readyToDraw"), "absent surface must remain nondrawable");
            invoke(value, "surfaceCreated"); set(value, "mPaused", true);
            synchronized (MANAGER) { invoke(value, "consumePendingSurfaceChangeLocked"); }
            require(!(Boolean)invoke(value, "readyToDraw"), "patch must not unpause the renderer");
            set(value, "mPaused", false); set(value, "mSurfaceIsBad", true);
            synchronized (MANAGER) { invoke(value, "consumePendingSurfaceChangeLocked"); }
            require(!(Boolean)invoke(value, "readyToDraw"), "unrelated bad surface must not be blindly retried");
        } else {
            require(!(Boolean)invoke(value, "readyToDraw"), "control must retain the lost-edge stall");
        }
        System.out.println("SURFACE_HOST_RESULT variant=" + args[0] + " passed=true lost_edge=" + (latched ? "recovered" : "stalled") + " scope=controlled-fields-no-GPU");
    }
}
