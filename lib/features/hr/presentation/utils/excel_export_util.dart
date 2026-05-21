import 'package:excel/excel.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ExcelExportUtil {
  static Future<String> generateEmployeeExcel(
    List<Map<String, dynamic>> employees,
  ) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Employees'];

      // Define headers
      final headers = [
        'Emp ID',
        'Name',
        'Email',
        'Phone',
        'Address',
        'DOB',
        'Blood Group',
        'Emergency Contact',
        'Aadhar',
        'PAN',
        'Role',
        'Status',
        'Salary',
        'Joining Date',
        'Login Status',
        'Created By (ID)',
        'Created By (Name)',
        'Created At',
      ];

      // Add headers with formatting
      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#4472C4'),
          fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        );
      }

      // Add employee data
      for (int row = 0; row < employees.length; row++) {
        final emp = employees[row];
        final values = [
          emp['empId'] ?? '',
          emp['empName'] ?? '',
          emp['email'] ?? '',
          emp['phone'] ?? '',
          emp['address'] ?? '',
          emp['dob'] ?? '',
          emp['bloodGroup'] ?? '',
          emp['emergencyContact'] ?? '',
          emp['aadharNumber'] ?? '',
          emp['panCardNumber'] ?? '',
          emp['roleName'] ?? '',
          emp['status'] ?? '',
          emp['salary'] ?? '0',
          emp['empDate'] ?? '',
          emp['loginStatus'] ?? '',
          emp['createdByEmpId'] ?? '',
          emp['createdByName'] ?? '',
          emp['createdAt'] ?? '',
        ];

        for (int col = 0; col < values.length; col++) {
          final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row + 1));
          cell.value = TextCellValue(values[col].toString());
        }
      }

      // Auto-fit columns
      for (int i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, 18);
      }

      // Save file
      final fileName = 'Employees_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      
      if (kIsWeb) {
        // Web platform - not supported for mobile build
        throw Exception('Export not supported on web platform');
      } else {
        // Mobile/Desktop platform
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(excel.encode()!);
        return filePath;
      }
    } catch (e) {
      throw Exception('Error generating Excel: $e');
    }
  }
}
