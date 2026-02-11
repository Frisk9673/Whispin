import '../../models/user/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserValidator {
  /// 入力UserとFirestore保存データ(Map)を比較し、
  /// 全項目一致ならtrue、不一致があればfalseを返す
  static bool isConsistent(User user, Map<String, dynamic> savedData) {
    final inputMap = user.toMap();

    for (final entry in inputMap.entries) {
      final key = entry.key;
      final inputValue = entry.value;
      final savedValue = savedData[key];

      // Timestamp vs DateTime の比較に対応
      if (inputValue is DateTime && savedValue != null) {
        final savedAsDate = savedValue is DateTime
            ? savedValue
            : (savedValue is Timestamp ? savedValue.toDate() : null);

        if (savedAsDate == null || inputValue.compareTo(savedAsDate) != 0) {
          return false;
        }
        continue;
      }

      // 通常比較
      if (inputValue != savedValue) {
        return false;
      }
    }

    return true;
  }
}
