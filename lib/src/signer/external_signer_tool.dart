import 'package:nostr_core_dart/src/channel/core_method_channel.dart';
import 'package:nostr_core_dart/src/signer/signer_permission_model.dart';
import 'package:nostr_core_dart/src/signer/signer_config.dart';

///Title: external_signer_tool
///Description: External signer tool with support for both Intent and Content Provider communication
///Copyright: Copyright (c) 2021
///@author Michael
///CreateTime: 2023/11/29 11:21
class ExternalSignerTool {
  
  /// Initialize signer configuration
  static void initialize() {
    SignerConfigManager.instance.initialize();
  }

  /// Set current signer
  static void setSigner(String signerKey) {
    SignerConfigManager.instance.setSigner(signerKey);
  }

  /// Get current signer configuration
  static SignerConfig? getCurrentConfig() {
    return SignerConfigManager.instance.currentConfig;
  }

  ///get_public_key
  static Future<String?> getPubKey() async {
    final config = getCurrentConfig();
    
    if (config == null) {
      // Fallback to default behavior
      return _getPubKeyWithIntent();
    }

    switch (config.callMethod) {
      case SignerCallMethod.intent:
        return _getPubKeyWithIntent();
      case SignerCallMethod.contentProvider:
        return _getPubKeyWithContentProvider(config);
      case SignerCallMethod.auto:
        // Try Content Provider first, fallback to Intent
        final result = await _getPubKeyWithContentProvider(config);
        if (result != null) {
          return result;
        } else {
          return await _getPubKeyWithIntent();
        }
    }
  }

  /// Get public key using Intent method
  static Future<String?> _getPubKeyWithIntent() async {
    final config = getCurrentConfig();
    final Object? result = await CoreMethodChannel.channelChatCore.invokeMethod(
      'nostrsigner',
      {
        'type': SignerType.GET_PUBLIC_KEY.name,
        'requestCode': SignerType.GET_PUBLIC_KEY.requestCode,
        'permissions': SignerPermissionModel.defaultPermissions(),
        'packageName': config?.packageName, // Pass the correct package name
        'useContentProvider': config?.callMethod == SignerCallMethod.auto, // Use Content Provider first for auto mode
        'callMethod': config?.callMethod.name ?? 'intent', // Pass the call method
      },
    );
    if (result == null) return null;
    final Map<String, String> resultMap = (result as Map).map((key, value) {
      return MapEntry(key as String, value as String);
    });
    return resultMap['result'] ?? resultMap['signature'];
  }

  /// Get public key using Content Provider method
  static Future<String?> _getPubKeyWithContentProvider(SignerConfig config) async {
    final Object? result = await CoreMethodChannel.channelChatCore.invokeMethod(
      'nostrsigner_content_provider',
      {
        'type': SignerType.GET_PUBLIC_KEY.name,
        'packageName': config.packageName,
        'contentProviderUri': config.getContentProviderUri('get_public_key'),
        'data': ['login'], // Content Provider parameters
      },
    );
    
    if (result == null) {
      return null;
    }
    
    final Map<String, String> resultMap = (result as Map).map((key, value) {
      return MapEntry(key as String, value as String);
    });
    return resultMap['result'];
  }

  ///sign_event
  ///@return signature、id、event
  static Future<Map<String, String>?> signEvent(String eventJson, String id, String current_user) async {
    final config = getCurrentConfig();
    if (config == null) {
      return _signEventWithIntent(eventJson, id, current_user);
    }

    switch (config.callMethod) {
      case SignerCallMethod.intent:
        return _signEventWithIntent(eventJson, id, current_user);
      case SignerCallMethod.contentProvider:
        return _signEventWithContentProvider(config, eventJson, id, current_user);
      case SignerCallMethod.auto:
        final result = await _signEventWithContentProvider(config, eventJson, id, current_user);
        return result ?? await _signEventWithIntent(eventJson, id, current_user);
    }
  }

  /// Sign event using Intent method
  static Future<Map<String, String>?> _signEventWithIntent(String eventJson, String id, String current_user) async {
    final config = getCurrentConfig();
    final Object? result = await CoreMethodChannel.channelChatCore.invokeMethod(
      'nostrsigner',
      {
        'type': SignerType.SIGN_EVENT.name,
        'id': id,
        'pubKey': "",
        'current_user': current_user,
        'requestCode': SignerType.SIGN_EVENT.requestCode,
        'extendParse': eventJson,
        'packageName': config?.packageName, // Pass the correct package name
        'useContentProvider': config?.callMethod == SignerCallMethod.auto, // Use Content Provider first for auto mode
        'callMethod': config?.callMethod.name ?? 'intent', // Pass the call method
      },
    );
    if (result == null) return null;
    final Map<String, String> resultMap = (result as Map).map((key, value) {
      return MapEntry(key as String, value as String);
    });
    return resultMap;
  }

  /// Sign event using Content Provider method
  static Future<Map<String, String>?> _signEventWithContentProvider(
    SignerConfig config, String eventJson, String id, String current_user) async {
    final Object? result = await CoreMethodChannel.channelChatCore.invokeMethod(
      'nostrsigner_content_provider',
      {
        'type': SignerType.SIGN_EVENT.name,
        'packageName': config.packageName,
        'contentProviderUri': config.getContentProviderUri('sign_event'),
        'data': [eventJson, '', current_user], // Content Provider parameters
      },
    );
    if (result == null) return null;
    final Map<String, String> resultMap = (result as Map).map((key, value) {
      return MapEntry(key as String, value as String);
    });
    return resultMap;
  }

  ///sign_message
  static Future<Map<String, String>?> signMessage(String eventJson, String id, String current_user) async {
    final config = getCurrentConfig();
    final Object? result = await CoreMethodChannel.channelChatCore.invokeMethod(
      'nostrsigner',
      {
        'type': SignerType.SIGN_MESSAGE.name,
        'id': id,
        'pubKey': "",
        'current_user': current_user,
        'requestCode': SignerType.SIGN_MESSAGE.requestCode,
        'extendParse': eventJson,
        'packageName': config?.packageName, // Pass the correct package name
        'useContentProvider': config?.callMethod == SignerCallMethod.auto, // Use Content Provider first for auto mode
        'callMethod': config?.callMethod.name ?? 'intent', // Pass the call method
      },
    );
    if (result == null) return null;
    final Map<String, String> resultMap = (result as Map).map((key, value) {
      return MapEntry(key as String, value as String);
    });
    return resultMap;
  }

  ///nip04_encrypt
  ///@return signature、id
  static Future<Map<String, String>?> nip04Encrypt(String plaintext, String id, String current_user, String pubKey) async {
    final config = getCurrentConfig();
    final Object? result = await CoreMethodChannel.channelChatCore.invokeMethod(
      'nostrsigner',
      {
        'type': SignerType.NIP04_ENCRYPT.name,
        'id': id,
        'current_user': current_user,
        'pubKey': pubKey,
        'requestCode': SignerType.NIP04_ENCRYPT.requestCode,
        'extendParse': plaintext,
        'packageName': config?.packageName, // Pass the correct package name
        'useContentProvider': config?.callMethod == SignerCallMethod.auto, // Use Content Provider first for auto mode
        'callMethod': config?.callMethod.name ?? 'intent', // Pass the call method
      },
    );
    if (result == null) return null;
    final Map<String, String> resultMap = (result as Map).map((key, value) {
      return MapEntry(key as String, value as String);
    });
    return resultMap;
  }

  ///nip44_encrypt
  ///@return signature、id
  static Future<Map<String, String>?> nip44Encrypt(String plaintext, String id, String current_user, String pubKey) async {
    final config = getCurrentConfig();
    final Object? result = await CoreMethodChannel.channelChatCore.invokeMethod(
      'nostrsigner',
      {
        'type': SignerType.NIP44_ENCRYPT.name,
        'id': id,
        'current_user': current_user,
        'pubKey': pubKey,
        'requestCode': SignerType.NIP44_ENCRYPT.requestCode,
        'extendParse': plaintext,
        'packageName': config?.packageName, // Pass the correct package name
        'useContentProvider': config?.callMethod == SignerCallMethod.auto, // Use Content Provider first for auto mode
        'callMethod': config?.callMethod.name ?? 'intent', // Pass the call method
      },
    );
    if (result == null) return null;
    final Map<String, String> resultMap = (result as Map).map((key, value) {
      return MapEntry(key as String, value as String);
    });
    return resultMap;
  }

  ///nip04_decrypt
  ///@return signature、id
  static Future<Map<String, String>?> nip04Decrypt(String encryptedText, String id, String current_user, String pubKey) async {
    final config = getCurrentConfig();
    final Object? result = await CoreMethodChannel.channelChatCore.invokeMethod(
      'nostrsigner',
      {
        'type': SignerType.NIP04_DECRYPT.name,
        'id': id,
        'current_user': current_user,
        'pubKey': pubKey,
        'requestCode': SignerType.NIP04_DECRYPT.requestCode,
        'extendParse': encryptedText,
        'packageName': config?.packageName, // Pass the correct package name
        'useContentProvider': config?.callMethod == SignerCallMethod.auto, // Use Content Provider first for auto mode
        'callMethod': config?.callMethod.name ?? 'intent', // Pass the call method
      },
    );
    if (result == null) return null;
    final Map<String, String> resultMap = (result as Map).map((key, value) {
      return MapEntry(key as String, value as String);
    });
    return resultMap;
  }

  ///nip44_decrypt
  ///@return signature、id
  static Future<Map<String, String>?> nip44Decrypt(String encryptedText, String id, String current_user, String pubKey) async {
    final config = getCurrentConfig();
    final Object? result = await CoreMethodChannel.channelChatCore.invokeMethod(
      'nostrsigner',
      {
        'type': SignerType.NIP44_DECRYPT.name,
        'id': id,
        'current_user': current_user,
        'pubKey': pubKey,
        'requestCode': SignerType.NIP44_DECRYPT.requestCode,
        'extendParse': encryptedText,
        'packageName': config?.packageName, // Pass the correct package name
        'useContentProvider': config?.callMethod == SignerCallMethod.auto, // Use Content Provider first for auto mode
        'callMethod': config?.callMethod.name ?? 'intent', // Pass the call method
      },
    );
    if (result == null) return null;
    final Map<String, String> resultMap = (result as Map).map((key, value) {
      return MapEntry(key as String, value as String);
    });
    return resultMap;
  }

  ///decrypt_zap_event
  ///@return signature、id
  static Future<Map<String, String>?> decryptZapEvent(String encryptedText, String id, String current_user) async {
    final config = getCurrentConfig();
    final Object? result = await CoreMethodChannel.channelChatCore.invokeMethod(
      'nostrsigner',
      {
        'type': SignerType.DECRYPT_ZAP_EVENT.name,
        'id': id,
        'current_user': current_user,
        'requestCode': SignerType.DECRYPT_ZAP_EVENT.requestCode,
        'extendParse': encryptedText,
        'packageName': config?.packageName, // Pass the correct package name
        'useContentProvider': config?.callMethod == SignerCallMethod.auto, // Use Content Provider first for auto mode
        'callMethod': config?.callMethod.name ?? 'intent', // Pass the call method
      },
    );
    if (result == null) return null;
    final Map<String, String> resultMap = (result as Map).map((key, value) {
      return MapEntry(key as String, value as String);
    });
    return resultMap;
  }
}

enum SignerType {
  SIGN_EVENT,
  SIGN_MESSAGE,
  NIP04_ENCRYPT,
  NIP04_DECRYPT,
  NIP44_ENCRYPT,
  NIP44_DECRYPT,
  GET_PUBLIC_KEY,
  DECRYPT_ZAP_EVENT,
}

extension SignerTypeEx on SignerType {
  String get name {
    switch (this) {
      case SignerType.GET_PUBLIC_KEY:
        return 'get_public_key';
      case SignerType.SIGN_EVENT:
        return 'sign_event';
      case SignerType.SIGN_MESSAGE:
        return 'sign_message';
      case SignerType.NIP04_ENCRYPT:
        return 'nip04_encrypt';
      case SignerType.NIP04_DECRYPT:
        return 'nip04_decrypt';
      case SignerType.NIP44_ENCRYPT:
        return 'nip44_encrypt';
      case SignerType.NIP44_DECRYPT:
        return 'nip44_decrypt';
      case SignerType.DECRYPT_ZAP_EVENT:
        return 'decrypt_zap_event';
    }
  }

  int get requestCode {
    switch (this) {
      case SignerType.GET_PUBLIC_KEY:
        return 101;
      case SignerType.SIGN_EVENT:
        return 102;
      case SignerType.NIP04_ENCRYPT:
        return 103;
      case SignerType.NIP04_DECRYPT:
        return 104;
      case SignerType.NIP44_ENCRYPT:
        return 105;
      case SignerType.NIP44_DECRYPT:
        return 106;
      case SignerType.DECRYPT_ZAP_EVENT:
        return 107;
      case SignerType.SIGN_MESSAGE:
        return 108;
    }
  }
}
