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
      SignerPermissionModel(type: "sign_event", kind: 22456),
      SignerPermissionModel(type: "sign_event", kind: 3),
      SignerPermissionModel(type: "sign_event", kind: 4),
      SignerPermissionModel(type: "sign_event", kind: 13),
      SignerPermissionModel(type: "sign_event", kind: 14),
      SignerPermissionModel(type: "sign_event", kind: 8),
      SignerPermissionModel(type: "sign_event", kind: 1059),
      SignerPermissionModel(type: "sign_event", kind: 30000),
      SignerPermissionModel(type: "sign_event", kind: 30001),
      SignerPermissionModel(type: "sign_event", kind: 1),
      SignerPermissionModel(type: "sign_event", kind: 0),
      SignerPermissionModel(type: "sign_event", kind: 10100),
      SignerPermissionModel(type: "sign_event", kind: 10101),
      SignerPermissionModel(type: "sign_event", kind: 10102),
      SignerPermissionModel(type: "sign_event", kind: 10103),
      SignerPermissionModel(type: "sign_event", kind: 10104),
      SignerPermissionModel(type: "sign_event", kind: 25050),
      SignerPermissionModel(type: "sign_event", kind: 10002),
      SignerPermissionModel(type: "sign_event", kind: 30008),
      SignerPermissionModel(type: "sign_event", kind: 30009),
      SignerPermissionModel(type: "sign_event", kind: 9734),
      SignerPermissionModel(type: "sign_event", kind: 9733),
      SignerPermissionModel(type: "sign_event", kind: 23194),
      SignerPermissionModel(type: "sign_event", kind: 40),
      SignerPermissionModel(type: "sign_event", kind: 41),
      SignerPermissionModel(type: "sign_event", kind: 42),
      SignerPermissionModel(type: "sign_event", kind: 43),
      SignerPermissionModel(type: "sign_event", kind: 5),
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
