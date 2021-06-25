import 'package:flutter/services.dart';

class VPN {

  static const MethodChannel _channel = MethodChannel('flutter.native/dns');


  ///Start VPN easily
  static Future<void> startVpn(String ip, String dns) async {
    return _channel.invokeMethod("start", {
        "ip": ip,
        "dns": dns,
      },
    );
  }
}