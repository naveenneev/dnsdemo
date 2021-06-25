package com.example.screencoach

import android.annotation.TargetApi
import android.app.PendingIntent
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor

class LocalVPNService : VpnService() {
    private var vpnInterface: ParcelFileDescriptor? = null
    private val pendingIntent: PendingIntent? = null
    private var ip: String? = null
    private var dns: String? = null
    override fun onCreate() {
        super.onCreate()
        isRunning = true
    }

    @TargetApi(Build.VERSION_CODES.LOLLIPOP)
    private fun setupVPN() {
        if (vpnInterface == null) {
            val builder: Builder = Builder()

            /* PackageManager packageManager = getPackageManager();
            for (String appPackage: appPackages) {
                try {
                    packageManager.getPackageInfo(appPackage, 0);
                    builder.addAllowedApplication(appPackage);
                } catch (PackageManager.NameNotFoundException e) {
                    // The app isn't installed.
                }
            }*/builder.addAddress(ip, 32)
            builder.addDnsServer(dns)
            builder.addRoute("::", 0)
            vpnInterface =
                builder.setSession("Local VPN").setConfigureIntent(pendingIntent).establish()
        }
    }

    override fun onStartCommand(intent: Intent, flags: Int, startId: Int): Int {
        ip = intent.getStringExtra("ip")
        dns = intent.getStringExtra("dns")
        setupVPN()
        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        isRunning = false
        cleanup()
    }

    private fun cleanup() {
        ByteBufferPool.clear()
    }

    companion object {
        const val BROADCAST_VPN_STATE = "xyz.hexene.localvpn.VPN_STATE"
        var isRunning = false
            private set
    }
}