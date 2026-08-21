import 'package:hive_ce/hive.dart';

mixin class HiveService {
  Future<Box<T>> getBox<T>(String boxName) async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<T>(boxName);
    }
    return await Hive.openBox<T>(boxName);
  }

  Future<Box<T>> getEncryptedBox<T>(
    String boxName,
    List<int> encryptionKey,
  ) async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<T>(boxName);
    }
    final cipher = HiveAesCipher(encryptionKey);
    return await Hive.openBox<T>(boxName, encryptionCipher: cipher);
  }

  Future<void> closeBox(String boxName) async {
    if (!Hive.isBoxOpen(boxName)) return;
    await Hive.box(boxName).close();
  }
}
