package com.example.screencoach

import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.VpnService
import android.os.Bundle
import androidx.annotation.NonNull
import androidx.annotation.Nullable
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var ip = ""
    private var dns = ""
    private val vpnStateReceiver: BroadcastReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (LocalVPNService.BROADCAST_VPN_STATE == intent.getAction()) {
                if (intent.getBooleanExtra("running", false));
            }
        }
    }

    protected override fun onCreate(@Nullable savedInstanceState: Bundle?) {
        LocalBroadcastManager.getInstance(this).registerReceiver(
            vpnStateReceiver,
            IntentFilter(LocalVPNService.BROADCAST_VPN_STATE)
        )
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.getDartExecutor().getBinaryMessenger(),
            CHANNEL
        ).setMethodCallHandler { call, result ->
            if (call.method.equals("start")) {
                ip = call.argument("ip")!!
                dns = call.argument("dns")!!
                startVPN()
            }
        }

        /*vpnControlMethod.setMethodCallHandler((call, result) -> {
                if (call.method.equals("start")) {
                        ip = call.argument("ip");
                        dns = call.argument("dns");
                        startVPN();
                    result.success(null);

                }
        });*/
    }

    private fun startVPN() {
        val vpnIntent: Intent = VpnService.prepare(this)
        if (vpnIntent != null) startActivityForResult(
            vpnIntent,
            VPN_REQUEST_CODE
        ) else onActivityResult(
            VPN_REQUEST_CODE, Activity.RESULT_OK, null
        )
    }

    protected override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == VPN_REQUEST_CODE && resultCode == Activity.RESULT_OK) {
            startService(
                Intent(this, LocalVPNService::class.java)
                    .putExtra("ip", ip)
                    .putExtra("dns", dns)
            )
            /*enableButton(false);*/
        }
    }

    protected override fun onResume() {
        super.onResume()

/*
        enableButton(!waitingForVPNStart && !LocalVPNService.isRunning());
*/
    } /*private void enableButton(boolean enable)
    {
        final Button vpnButton = (Button) findViewById(R.id.vpn);
        if (enable)
        {
            vpnButton.setEnabled(true);
            vpnButton.setText(R.string.start_vpn);
        }
        else
        {
            vpnButton.setEnabled(false);
            vpnButton.setText(R.string.stop_vpn);
        }
    }*/

    companion object {
        private const val VPN_REQUEST_CODE = 0x0F
        private const val CHANNEL = "flutter.native/dns"
    }
}