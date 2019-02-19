import 'package:dhcp/dhcp.dart';
import 'package:network/foundation.dart';
import 'package:network/ip.dart';
import 'package:raw/raw.dart';
import 'package:raw/test_helpers.dart';
import 'package:test/test.dart';

void main() {
  group("DhcpRequest", () {
    group("example #1", () {
      List<int> exampleBytes;
      DhcpPacket example;

      setUp(() {
        example = DhcpPacket();
        example.op = 1;
        example.options = [
          DnsDhcpOption()..ipAddresses = [Ip4Address.loopback],
        ];
      });
      setUp(() {
        exampleBytes = const DebugHexDecoder().convert("""
          0x0000: 0100 0000  0000 0000  0000 0000  0000 0000
          0x0010: 0000 0000  0000 0000  0000 0000  0000 0000
          0x0020: 0000 0000  0000 0000  0000 0000  0000 0000
          0x0030: 0000 0000  0000 0000  0000 0000  0000 0000
          0x0040: 0000 0000  0000 0000  0000 0000  0000 0000
          0x0050: 0000 0000  0000 0000  0000 0000  0000 0000
          0x0060: 0000 0000  0000 0000  0000 0000  0000 0000
          0x0070: 0000 0000  0000 0000  0000 0000  0000 0000
          0x0080: 0000 0000  0000 0000  0000 0000  0000 0000
          0x0090: 0000 0000  0000 0000  0000 0000  0000 0000
          0x00A0: 0000 0000  0000 0000  0000 0000  0000 0000
          0x00B0: 0000 0000  0000 0000  0000 0000  0000 0000
          0x00C0: 0000 0000  0000 0000  0000 0000  0000 0000
          0x00D0: 0000 0000  0000 0000  0000 0000  0000 0000
          0x00E0: 0000 0000  0000 0000  0000 0000  0000 0000
          0x00F0: 0000 0000  0000 0000  0000 0000  0000 0000
          0x0100: 6382 5363  0604 7f00  0001 ff00
        """);
      });

      test("encode, decode, encode", () {
        // encode
        final writer = RawWriter.withCapacity(500);
        example.encodeSelf(writer);
        final encoded = writer.toUint8ListView();
        expect(encoded, byteListEquals(exampleBytes));
        final encodedReader = RawReader.withBytes(encoded);

        // encode -> decode
        final decoded = DhcpPacket();
        decoded.decodeSelf(encodedReader);

        // encode -> decode -> encode
        // (the next two lines should both encode)
        expect(decoded.toImmutableBytes(), byteListEquals(exampleBytes));
        expect(decoded, selfEncoderEquals(example));
        expect(encodedReader.availableLengthInBytes, 0);
      });

      test("decode", () {
        final reader = RawReader.withBytes(exampleBytes);
        final decoded = DhcpPacket();
        decoded.decodeSelf(reader);
        expect(decoded, selfEncoderEquals(example));
        expect(reader.availableLengthInBytes, 0);
      });
    });
  });
}
