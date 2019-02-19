import 'dart:typed_data';

import 'package:network/foundation.dart';
import 'package:network/ip.dart';

import 'dhcp_options.dart';

const Protocol dhcp4 = Protocol("DHCP");

class DhcpPacket extends Packet {
  static const int magicInt = 0x63825363;

  final ByteData _data = ByteData(64);

  /// 1-byte operation code
  int get op => _data.getUint8(0);

  set op(int value) {
    _data.setUint8(0, value);
  }

  /// 1-byte hardware address type
  int get hwAddrType => _data.getUint8(1);

  set hwAddrType(int value) {
    _data.setUint8(1, value);
  }

  /// 1-byte hardware address length
  int get hwAddrLength => _data.getUint8(2);

  set hwAddrLength(int value) {
    _data.setUint8(2, value);
  }

  /// 1-byte hops count
  int get hops => _data.getUint8(3);

  set hops(int value) {
    _data.setUint8(3, value);
  }

  /// 4-byte transaction identifier
  int get xid => _data.getUint32(4);

  set xit(int value) {
    _data.setUint32(4, value);
  }

  /// 2-byte seconds
  int get secs => _data.getUint16(8);

  set secs(int value) {
    _data.setUint16(8, value);
  }

  /// 2-byte flags
  int get flags => _data.getUint16(10);

  set flags(int value) {
    _data.setUint16(10, value);
  }

  /// 4-byte client IP address
  Ip4Address get ciAddr => Ip4Address.fromUint32(_data.getUint32(12));

  set ciAddr(Ip4Address value) {
    _data.setUint32(12, value.asUint32);
  }

  /// 4-byte your IP address
  Ip4Address get yiAddr => Ip4Address.fromUint32(_data.getUint32(16));

  set yiAddr(Ip4Address value) {
    _data.setUint32(16, value.asUint32);
  }

  /// 4-byte server IP address
  Ip4Address get siAddr => Ip4Address.fromUint32(_data.getUint32(20));

  set siAddr(Ip4Address value) {
    _data.setUint32(20, value.asUint32);
  }

  /// 4-byte gateway IP address
  Ip4Address get giAddr => Ip4Address.fromUint32(_data.getUint32(24));

  set giAddr(Ip4Address value) {
    _data.setUint32(24, value.asUint32);
  }

  /// 16-byte client hardware address
  Uint8List get chAddr {
    return Uint8List.view(
      _data.buffer,
      _data.offsetInBytes + 28,
      44,
    );
  }

  set chAddr(List<int> value) {
    if (value.length > 16) {
      throw ArgumentError.value(value);
    }
    final writer = RawWriter.withByteData(_data);
    writer.length = 28;
    writer.writeBytes(value);
    writer.writeZeroes(16 - value.length);
  }

  /// Options
  List<DhcpOption> options = const <DhcpOption>[];

  DhcpPacket();

  @override
  Protocol get protocol => dhcp4;

  @override
  void encodeSelf(RawWriter writer) {
    // Write fixed fields
    writer.writeByteData(_data);

    // Ignore legacy fields
    writer.writeZeroes(192);

    // Magic cookie
    writer.writeUint32(magicInt);

    // Options
    for (var option in options) {
      option.encodeSelf(writer);
    }

    writer.writeUint8(255);
    writer.writeUint8(0);
  }

  @override
  void decodeSelf(RawReader reader) {
    // Read fixed fields
    for (var i = 0; i < 64; i += 4) {
      final value = reader.readUint32();
      _data.setUint32(i, value);
    }

    // Ignore legacy fields
    reader.index += 192;

    // Skip possible magic cookie
    if (reader.previewUint32(0) == magicInt) {
      reader.index += 4;
    }

    // Read options
    final options = <DhcpOption>[];
    this.options = options;

    while (reader.availableLengthInBytes > 0) {
      final optionCode = reader.previewUint8(0);
      DhcpOption option;
      switch (optionCode) {
        case DhcpOption.subnet:
          option = SubnetDhcpOption();
          break;
        case DhcpOption.router:
          option = RouterDhcpOption();
          break;
        case DhcpOption.dns:
          option = DnsDhcpOption();
          break;
        case DhcpOption.leaseTime:
          option = LeaseTimeDhcpOption();
          break;
        case DhcpOption.type:
          option = TypeDhcpOption();
          break;
        default:
          option = UnsupportedDhcpOption(optionCode);
      }
      option.decodeSelf(reader);
      if (optionCode == 255) {
        break;
      }
      options.add(option);
    }
  }

  @override
  int encodeSelfCapacity() {
    var n = 64 + 192;

    // Magic bytes
    n += 4;

    // Options
    for (var option in options) {
      n += option.encodeSelfCapacity();
    }

    n += 2;
    return n;
  }
}
