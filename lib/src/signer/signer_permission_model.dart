///Title: signer_permission_model
///Description: TODO(Fill in by oneself)
///Copyright: Copyright (c) 2021
///@author Michael
///CreateTime: 2023/11/30 15:58
class SignerPermissionModel {
  final String type;
  final int? kind;

  SignerPermissionModel({required this.type, this.kind});

  String toJson() {
    return '{"type":"$type","kind":${kind ?? 'null'}}';
  }

  static String defaultPermissions() {
    final permissions = [
      SignerPermissionModel(type: "sign_event", kind: 22242),
      SignerPermissionModel(type: "nip04_encrypt"),
      SignerPermissionModel(type: "nip04_decrypt"),
      SignerPermissionModel(type: "nip44_encrypt"),
      SignerPermissionModel(type: "nip44_decrypt"),
      SignerPermissionModel(type: "decrypt_zap_event"),
    ];

    final jsonArray = StringBuffer('[');
    for (var i = 0; i < permissions.length; i++) {
      jsonArray.write(permissions[i].toJson());
      if (i < permissions.length - 1) {
        jsonArray.write(',');
      }
    }
    jsonArray.write(']');

    return jsonArray.toString();
  }

}
