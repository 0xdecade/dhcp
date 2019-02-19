import 'dart:typed_data';

import 'package:network/foundation.dart';
import 'package:network/ip.dart';

abstract class DhcpOption extends SelfEncoder with SelfDecoder {
  static const int subnet = 1;
  static const int router = 3;
  static const int dns = 6;
  static const int leaseTime = 51;
  static const int type = 53;
  static const int parameterRequestList = 55;

  int get code;
}

abstract class BytesDhcpOption extends DhcpOption {
  Uint8List bytes = Uint8List(0);

  @override
  void decodeSelf(RawReader reader) {
    // Type
    reader.readUint8();

    // Length
    final length = reader.readUint8();

    // Content
    bytes = reader.readUint8ListViewOrCopy(length);
  }

  @override
  int encodeSelfCapacity() => 2 + bytes.length;

  @override
  void encodeSelf(RawWriter writer) {
    // Type
    writer.writeUint8(code);

    // Length
    writer.writeUint8(bytes.length);

    // Content
    writer.writeBytes(bytes);
  }
}

abstract class IpDhcpOption extends DhcpOption {
  List<Ip4Address> ipAddresses = <Ip4Address>[];

  @override
  void decodeSelf(RawReader reader) {
    // Type
    reader.readUint8();

    // Length
    var length = reader.readUint8();

    // IPs
    final ipAddresses = <Ip4Address>[];
    while (length >= 4) {
      final value = reader.readUint32();
      ipAddresses.add(Ip4Address.fromUint32(value));
      length -= 4;
    }
    this.ipAddresses = ipAddresses;
  }

  @override
  int encodeSelfCapacity() => 2 + 4 * ipAddresses.length;

  @override
  void encodeSelf(RawWriter writer) {
    // Type
    writer.writeUint8(code);

    // Length
    writer.writeUint8(4 * ipAddresses.length);

    // Content
    for (var ipAddress in ipAddresses) {
      ipAddress.encodeSelf(writer);
    }
  }
}

class ParameterRequestListDhcpOption extends BytesDhcpOption {
  @override
  int get code => DhcpOption.parameterRequestList;

  ParameterRequestListDhcpOption();
}

class RouterDhcpOption extends IpDhcpOption {
  @override
  int get code => DhcpOption.router;

  RouterDhcpOption();
}

class DnsDhcpOption extends IpDhcpOption {
  @override
  int get code => DhcpOption.dns;

  DnsDhcpOption();
}

class TypeDhcpOption extends BytesDhcpOption {
  static const int discover = 1;
  static const int offer = 2;
  static const int request = 3;
  static const int decline = 4;
  static const int ack = 5;

  @override
  int get code => DhcpOption.type;

  TypeDhcpOption();
}

class LeaseTimeDhcpOption extends BytesDhcpOption {
  @override
  int get code => DhcpOption.leaseTime;

  LeaseTimeDhcpOption();
}

class SubnetDhcpOption extends IpDhcpOption {
  @override
  int get code => DhcpOption.subnet;

  SubnetDhcpOption();
}

class UnsupportedDhcpOption extends BytesDhcpOption {
  final int code;

  UnsupportedDhcpOption(this.code);
}
