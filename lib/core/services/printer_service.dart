import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

class PrinterService {
  static final PrinterService _instance = PrinterService._internal();
  factory PrinterService() => _instance;
  PrinterService._internal();

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
          final response = await http.get(Uri.parse(s.logoUrl!));
          if (response.statusCode == 200) {
            final originalImage = img.decodeImage(response.bodyBytes);
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
    for (var item in t.items) {
      final name = item.product.name;
      final qty = item.quantity;
      final price = item.unitPrice;
      final total = item.subtotal;
      
      bluetooth.printCustom(name, 1, 0);
      bluetooth.printLeftRight(
        "$qty ${item.product.unit} x ${price.toInt()}", 
        "${total.toInt()}", 
        1,
      );
    }
    
    bluetooth.printCustom("--------------------------------", 1, 1);
    
    // Totals
    bluetooth.printLeftRight("Subtotal", "${t.subtotal.toInt()}", 1);
    if (t.discount != null) {
      bluetooth.printLeftRight("Diskon (${t.discount.name})", "-${t.discount.value.toInt()}", 1);
    }
    if (t.extraDiscount > 0) {
      bluetooth.printLeftRight("Diskon Tambahan", "-${t.extraDiscount.toInt()}", 1);
    }
    if (t.fee != null) {
      bluetooth.printLeftRight("Biaya (${t.fee.name})", "+${t.fee.value.toInt()}", 1);
    }
    if (t.extraFee > 0) {
      bluetooth.printLeftRight("Biaya Tambahan", "+${t.extraFee.toInt()}", 1);
    }
    
    bluetooth.printCustom("--------------------------------", 1, 1);
    bluetooth.printLeftRight("TOTAL", "${t.total.toInt()}", 2);
    
    bluetooth.printCustom("--------------------------------", 1, 1);
    bluetooth.printLeftRight("Bayar (${t.paymentMethod})", "${t.payAmount.toInt()}", 1);
    
    if (t.paymentMethod == 'Kasbon' || t.debtAmount > 0) {
      bluetooth.printLeftRight("Belum Lunas", "${t.debtAmount.toInt()}", 1);
    } else {
      final change = t.payAmount - t.total;
      if (change > 0) {
        bluetooth.printLeftRight("Kembali", "${change.toInt()}", 1);
      }
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
