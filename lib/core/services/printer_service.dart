import 'dart:convert';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

class PrinterService {
  static final PrinterService _instance = PrinterService._internal();
  factory PrinterService() => _instance;
  PrinterService._internal();

  String _formatRupiah(num amount) {
    final intAmount = amount.toInt();
    final str = intAmount.abs().toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
      count++;
    }
    final result = buffer.toString().split('').reversed.join();
    return intAmount < 0 ? '-$result' : result;
  }

  final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  BluetoothDevice? _selectedDevice;
  bool _isConnected = false;

  // Caching logo di memori untuk menghemat kuota internet dan mempercepat cetak
  Uint8List? _cachedLogoBytes;
  String? _cachedLogoUrl;
  int? _cachedLogoSize;

  BluetoothDevice? get selectedDevice => _selectedDevice;
  bool get isConnected => _isConnected;

  Future<List<BluetoothDevice>> getPairedDevices() async {
    try {
      return await bluetooth.getBondedDevices();
    } catch (e) {
      debugPrint('Error getting bonded devices: $e');
      return [];
    }
  }

  Future<bool> connect(BluetoothDevice device) async {
    try {
      final isConnected = await bluetooth.isConnected;
      if (isConnected == true) {
        await bluetooth.disconnect();
      }
      await bluetooth.connect(device);
      _selectedDevice = device;
      _isConnected = true;
      return true;
    } catch (e) {
      debugPrint('Error connecting: $e');
      _isConnected = false;
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await bluetooth.disconnect();
      _selectedDevice = null;
      _isConnected = false;
    } catch (e) {
      debugPrint('Error disconnecting: $e');
    }
  }

  Future<void> printReceipt(String content) async {
    final isConnected = await bluetooth.isConnected;
    if (isConnected != true) return;

    bluetooth.printCustom(content, 0, 0);
    bluetooth.printNewLine();
    bluetooth.printNewLine();
    bluetooth.paperCut();
  }

  Future<void> printTransaction(var transaction, var settings) async {
    final isConnected = await bluetooth.isConnected;
    if (isConnected != true) return;

    final t = transaction;
    final s = settings;
    
    // Print Logo (Menggunakan cache untuk menghemat kuota internet)
    if (s.logoUrl != null && s.logoUrl!.isNotEmpty) {
      try {
        // Cek apakah URL dan Size sama dengan cache, jika iya gunakan cache
        if (_cachedLogoBytes != null && _cachedLogoUrl == s.logoUrl && _cachedLogoSize == s.logoSize) {
          bluetooth.printImageBytes(_cachedLogoBytes!);
          bluetooth.printNewLine();
        } else {
          // Jika belum ada di cache atau berubah, download dan proses
          Uint8List? sourceBytes;
          if (s.logoUrl!.startsWith('data:image')) {
            final base64Str = s.logoUrl!.split(',').last;
            sourceBytes = base64Decode(base64Str);
          } else {
            final response = await http.get(Uri.parse(s.logoUrl!));
            if (response.statusCode == 200) {
              sourceBytes = response.bodyBytes;
            }
          }

          if (sourceBytes != null) {
            final originalImage = img.decodeImage(sourceBytes);
            if (originalImage != null) {
              int targetSize = s.logoSize;
              final resized = img.copyResize(originalImage, width: targetSize);
              final pngBytes = Uint8List.fromList(img.encodePng(resized));
              
              // Simpan ke cache
              _cachedLogoBytes = pngBytes;
              _cachedLogoUrl = s.logoUrl;
              _cachedLogoSize = targetSize;
              
              bluetooth.printImageBytes(pngBytes);
              bluetooth.printNewLine();
            }
          }
        }
      } catch (e) {
        debugPrint('Gagal mencetak logo: $e');
      }
    }

    // Header
    if (s.name.isNotEmpty) {
      bluetooth.printCustom(s.name, 3, 1); // Size 3, Center
    } else {
      bluetooth.printCustom("KEMBANG JAYA", 3, 1);
    }
    
    if (s.address.isNotEmpty) bluetooth.printCustom(s.address, 1, 1);
    if (s.phone.isNotEmpty) bluetooth.printCustom("WA: ${s.phone}", 1, 1);
    
    bluetooth.printCustom("--------------------------------", 1, 1);
    
    // Info
    bluetooth.printCustom("Tgl  : ${t.date.day}/${t.date.month}/${t.date.year} ${t.date.hour}:${t.date.minute.toString().padLeft(2, '0')}", 1, 0);
    bluetooth.printCustom("Kasir: ${t.cashierName}", 1, 0);
    if (t.customerName != null && t.customerName!.isNotEmpty) {
      bluetooth.printCustom("Plgn : ${t.customerName}", 1, 0);
    }
    bluetooth.printCustom("Trx  : ${t.id}", 1, 0);
    
    bluetooth.printCustom("--------------------------------", 1, 1);

    // Items
    double totalSavings = 0;
    for (var item in t.items) {
      final name = item.product.name.replaceAll(RegExp(r'\s*Grade.*', caseSensitive: false), '');
      final qty = item.quantity;
      final price = item.unitPrice;
      final total = item.subtotal;
      final itemDiscount = item.itemDiscount * qty;
      totalSavings += itemDiscount;
      
      final displayName = name.length > 32 ? '${name.substring(0, 32)}...' : name;
      bluetooth.printCustom(displayName, 1, 0); //
      
      if (item.itemDiscount > 0) {
        bluetooth.printLeftRight(
          "$qty ${item.product.unit} x ${_formatRupiah(price)}", 
          "", 
          1,
        );
        bluetooth.printLeftRight(
          "  Diskon (-${_formatRupiah(itemDiscount)})", 
          "${_formatRupiah(total)}", 
          1,
        );
      } else {
        bluetooth.printLeftRight(
          "$qty ${item.product.unit} x ${_formatRupiah(price)}", 
          "${_formatRupiah(total)}", 
          0,
        );
      }
    }
    
    bluetooth.printCustom("--------------------------------", 1, 1);
    
    // Totals
    bluetooth.printLeftRight("Subtotal", "${_formatRupiah(t.subtotal)}", 1);
    if (t.discount != null) {
      totalSavings += t.discount!.value;
      bluetooth.printLeftRight("Diskon (${t.discount!.name})", "-${_formatRupiah(t.discount!.value)}", 1);
    }
    if (t.extraDiscount > 0) {
      totalSavings += t.extraDiscount;
      bluetooth.printLeftRight("Diskon Tambahan", "-${_formatRupiah(t.extraDiscount)}", 1);
    }
    if (t.fee != null) {
      bluetooth.printLeftRight("Biaya (${t.fee.name})", "+${_formatRupiah(t.fee.value)}", 1);
    }
    if (t.extraFee > 0) {
      bluetooth.printLeftRight("Biaya Tambahan", "+${_formatRupiah(t.extraFee)}", 1);
    }
    
    bluetooth.printCustom("--------------------------------", 1, 1);
    bluetooth.printLeftRight("TOTAL", "${_formatRupiah(t.total)}", 1); // nanti ganti jadi 1
    
    bluetooth.printCustom("--------------------------------", 1, 1);
    bluetooth.printLeftRight("Bayar (${t.paymentMethod})", "${_formatRupiah(t.payAmount)}", 1);
    
    if (t.paymentMethod == 'Kasbon' || t.debtAmount > 0) {
      bluetooth.printLeftRight("Belum Lunas", "${_formatRupiah(t.debtAmount)}", 1);
    } else {
      final change = t.payAmount - t.total;
      if (change > 0) {
        bluetooth.printLeftRight("Kembali", "${_formatRupiah(change)}", 1);
      }
    }

    if (totalSavings > 0) {
      bluetooth.printLeftRight("Anda Hemat", "${_formatRupiah(totalSavings)}", 1);
    }
    
    bluetooth.printCustom("--------------------------------", 1, 1);
    
    // Footer
    bluetooth.printCustom("Terima Kasih", 2, 1);
    bluetooth.printCustom("Barang yang sudah dibeli", 1, 1);
    bluetooth.printCustom("tidak dapat ditukar/dikembalikan", 1, 1);
    
    bluetooth.printNewLine();
    bluetooth.printNewLine();
    bluetooth.paperCut();
  }
}
