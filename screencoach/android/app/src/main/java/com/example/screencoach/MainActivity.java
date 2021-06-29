package com.example.screencoach;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.net.VpnService;
import android.os.Bundle;
import android.os.Handler;
import android.os.IBinder;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.example.screencoach.service.LocalVpnService;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;



public class MainActivity extends FlutterActivity {
    public static final int REQUEST_VPN = 1;
    Handler statusHandler = new Handler();
    private LocalVpnService service;
    private static final int VPN_REQUEST_CODE = 0x0F;
    private static final String CHANNEL = "flutter.native/dns";
    private MethodChannel startVpn;
    private String dns = "";

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL).setMethodCallHandler((call, result) -> {
            if (call.method.equals("start")) {
                dns = call.argument("dns");
                if(isRunning()) {
                    stopVpn();
                    startVpn();
                } else {
                    startVpn();
                }
            }
        });


    }

    private ServiceConnection serviceConnection = new ServiceConnection() {
        public void onServiceConnected(ComponentName className, IBinder binder) {
            LocalVpnService.ServiceBinder serviceBinder = (LocalVpnService.ServiceBinder) binder;
            service = serviceBinder.getService();
        }

        public void onServiceDisconnected(ComponentName className) {
            service = null;
        }
    };

    @Override
    protected void onResume() {
        super.onResume();
        updateStatus();

        statusHandler.post(statusRunnable);

        Intent intent = new Intent(this, LocalVpnService.class);
        bindService(intent, serviceConnection, Context.BIND_AUTO_CREATE);
    }

    boolean isRunning() {
        return service != null && service.isRunning();
    }

    Runnable statusRunnable = new Runnable() {
        @Override
        public void run() {
            updateStatus();
            statusHandler.post(statusRunnable);
        }
    };

    @Override
    protected void onPause() {
        super.onPause();
        statusHandler.removeCallbacks(statusRunnable);
        unbindService(serviceConnection);
    }

    void updateStatus() {
        if (service == null) {
            return;
        }
        if (isRunning()) {
            /*start.setEnabled(false);
            hostEditText.setEnabled(false);
            stop.setEnabled(true);*/
        } else {
          /*  start.setEnabled(true);
            hostEditText.setEnabled(true);
            stop.setEnabled(false);*/
        }
    }

    private void stopVpn() {
        //start.setEnabled(true);
        //stop.setEnabled(false);
        LocalVpnService.stop(this);
    }

    private void startVpn() {
        Intent i = VpnService.prepare(this);
        if (i != null) {
            startActivityForResult(i, REQUEST_VPN);
        } else {
            onActivityResult(REQUEST_VPN, RESULT_OK, null);
        }
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (resultCode != RESULT_OK) {
            return;
        }
        if (requestCode == REQUEST_VPN) {
            //start.setEnabled(false);
            //stop.setEnabled(true);
            LocalVpnService.dns = dns;
            LocalVpnService.start(this);
        }
    }

}
