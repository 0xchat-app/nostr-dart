import 'package:flutter/services.dart';

///Title: core_method_channel
///Description: TODO(Fill in by oneself)
///Copyright: Copyright (c) 2021
///@author Michael
///CreateTime: 2023/11/29 17:39
class CoreMethodChannel{
  static const MethodChannel channelChatCore = MethodChannel('com.oxchat.nostrcore');


  ///check an app is installed/enabled
  static Future<bool> isAppInstalled(String packageName) async {
    final bool result = await channelChatCore.invokeMethod(
      'isAppInstalled',
      {
        'packageName': packageName,
      },
    );
    return result;
  }

  static Future<bool> isInstalledAmber() async {
    final bool result = await isAppInstalled('com.greenart7c3.nostrsigner');
    return result;
  }
}