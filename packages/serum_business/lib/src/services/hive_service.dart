import 'package:hive_ce/hive.dart';

mixin class HiveService {
  Future<Box> getBox(String boxName) async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box(boxName);
    }
    return await Hive.openBox(boxName);
  }

  Future<void> closeBox(String boxName) async {
    if (!Hive.isBoxOpen(boxName)) return;
    await Hive.box(boxName).close();
  }
}
