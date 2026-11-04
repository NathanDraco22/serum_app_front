import 'package:excel_plus/excel_plus.dart';

abstract class ExcelTemplate {
  Future<Excel> buildExcel();

  Future<List<int>?> buildBytes() async {
    final excel = await buildExcel();
    return excel.save();
  }
}
