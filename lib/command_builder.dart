
import 'dart:typed_data';

class CommandBuilder {
  // Preamble and header
  static const List<int> _preambleAndHeader = [0xA3, 0x1E, 0x1C, 0x00];

  static List<int> buildWifiCommand(String ssid, String password) {
    // This is a placeholder command ID and needs to be verified from the sniffing logs.
    const List<int> commandId = [0x01, 0x20];

    // Convert SSID and password to bytes
    List<int> ssidBytes = ssid.codeUnits;
    List<int> passwordBytes = password.codeUnits;

    // Construct the payload
    List<int> payload = [
      0x11, // Request byte
      ...commandId,
      ssidBytes.length,
      ...ssidBytes,
      passwordBytes.length,
      ...passwordBytes,
    ];

    // Build the full packet
    List<int> packet = [
      ..._preambleAndHeader,
      payload.length & 0xFF, // Payload length (little-endian)
      (payload.length >> 8) & 0xFF,
      ...payload,
    ];

    // Calculate and append CRC32 checksum
    int crc = _calculateCrc32(Uint8List.fromList(packet.sublist(2)));
    var crcBytes = ByteData(4)..setUint32(0, crc, Endian.little);
    packet.addAll(crcBytes.buffer.asUint8List());

    return packet;
  }

  static int _calculateCrc32(Uint8List bytes) {
    const int polynomial = 0xEDB88320;
    int crc = 0xFFFFFFFF;
    for (int byte in bytes) {
      crc ^= byte;
      for (int i = 0; i < 8; i++) {
        if ((crc & 1) == 1) {
          crc = (crc >> 1) ^ polynomial;
        } else {
          crc >>= 1;
        }
      }
    }
    return crc ^ 0xFFFFFFFF;
  }
}
