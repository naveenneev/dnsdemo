package com.example.screencoach.service;

import android.content.Context;
import android.content.Intent;
import android.net.VpnService;
import android.os.Binder;
import android.os.IBinder;
import android.os.Parcel;
import android.os.ParcelFileDescriptor;
import android.os.PowerManager;
import android.os.RemoteException;
import android.util.Log;
import java.util.Enumeration;
import java.net.Inet4Address;
import java.net.InetAddress;
import java.net.NetworkInterface;
import java.net.SocketException;
import java.io.IOException;

public class LocalVpnService extends VpnService {
    private static final String TAG = "Tun2Http.Service";
    private static final String ACTION_START = "start";
    private static final String ACTION_STOP = "stop";
    public static String dns = "";
    private static volatile PowerManager.WakeLock wlInstance = null;

    static {
        System.loadLibrary("tun2http");
    }

    private LocalVpnService.Builder lastBuilder = null;
    private ParcelFileDescriptor vpn = null;

    public static void start(Context context) {
        Intent intent = new Intent(context, LocalVpnService.class);
        intent.setAction(ACTION_START);
        context.startService(intent);
    }

    public static void stop(Context context) {
        Intent intent = new Intent(context, LocalVpnService.class);
        intent.setAction(ACTION_STOP);
        context.startService(intent);
    }

    private native void jni_init();

    private native int jni_get_mtu();

    private native void jni_done();

    @Override
    public IBinder onBind(Intent intent) {
        return new ServiceBinder();
    }

    public boolean isRunning() {
        return vpn != null;
    }

    private void start() {
        //if (vpn == null) {
            lastBuilder = getBuilder();
            vpn = startVPN(lastBuilder);
            if (vpn == null)
                throw new IllegalStateException("start failed");

        //}
    }

    private void stop() {
        if (vpn != null) {
            stopVPN(vpn);
            vpn = null;
        }
        stopForeground(true);
    }

    @Override
    public void onRevoke() {
        Log.i(TAG, "Revoke");

        stop();
        vpn = null;

        super.onRevoke();
    }

    private ParcelFileDescriptor startVPN(Builder builder) throws SecurityException {
        try {
            return builder.establish();
        } catch (SecurityException ex) {
            throw ex;
        } catch (Throwable ex) {
            Log.e(TAG, ex.toString() + "\n" + Log.getStackTraceString(ex));
            return null;
            }
    }

    private Builder getBuilder() {

        Builder builder = new Builder();
        builder.setSession("test");
        builder.addAddress(getLocalIpAddress(), 24);
        builder.addRoute("::", 0);
        builder.addDnsServer(dns);


        // MTU
        int mtu = jni_get_mtu();
        Log.i(TAG, "MTU=" + getLocalIpAddress());
        builder.setMtu(mtu);

        // AAdd list of allowed and disallowed applications

        // Add list of allowed applications
        return builder;
    }



    private void stopVPN(ParcelFileDescriptor pfd) {
        Log.i(TAG, "Stopping");
        try {
            pfd.close();
        } catch (IOException ex) {
            Log.e(TAG, ex.toString() + "\n" + Log.getStackTraceString(ex));
        }
    }


    @Override
    public void onCreate() {
        // Native init
        jni_init();
        super.onCreate();

    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        Log.i(TAG, "Received " + intent);
        // Handle service restart
        if (intent == null) {
            return START_STICKY;
        }

        if (ACTION_START.equals(intent.getAction())) {
            start();
        }
        if (ACTION_STOP.equals(intent.getAction())) {
            stop();
        }
        return START_STICKY;
    }

    @Override
    public void onDestroy() {
        Log.i(TAG, "Destroy");

        try {
            if (vpn != null) {
                stopVPN(vpn);
                vpn = null;
            }
        } catch (Throwable ex) {
            Log.e(TAG, ex.toString() + "\n" + Log.getStackTraceString(ex));
        }

        jni_done();

        super.onDestroy();
    }

    public class ServiceBinder extends Binder {
        @Override
        public boolean onTransact(int code, Parcel data, Parcel reply, int flags)
                throws RemoteException {
            // see Implementation of android.net.VpnService.Callback.onTransact()
            if (code == IBinder.LAST_CALL_TRANSACTION) {
                onRevoke();
                return true;
            }
            return super.onTransact(code, data, reply, flags);
        }

        public LocalVpnService getService() {
            return LocalVpnService.this;
        }
    }

    public static String getLocalIpAddress() {
        try {
            for (Enumeration<NetworkInterface> en = NetworkInterface.getNetworkInterfaces(); en.hasMoreElements();) {
                NetworkInterface intf = en.nextElement();
                for (Enumeration<InetAddress> enumIpAddr = intf.getInetAddresses(); enumIpAddr.hasMoreElements();) {
                    InetAddress inetAddress = enumIpAddr.nextElement();
                    if (!inetAddress.isLoopbackAddress() && inetAddress instanceof Inet4Address) {
                        return inetAddress.getHostAddress();
                    }
                }
            }
        } catch (SocketException ex) {
            ex.printStackTrace();
        }
        return null;
    }
}
