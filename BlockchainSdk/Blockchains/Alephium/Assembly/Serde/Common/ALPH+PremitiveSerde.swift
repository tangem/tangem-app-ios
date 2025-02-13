//
//  ALPH+PremitiveSerde.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension ALPH {
    struct BoolSerde: FixedSizeSerde {
        func serialize(_ input: Bool) -> Data {
            return Data([input ? 1 : 0])
        }

        func deserialize(_ input: Data) -> Result<Bool, Error> {
            guard let firstByte = input.first else {
                return .failure(ALPH.SerdeError.wrongFormat(message: "Empty input"))
            }

            switch firstByte {
            case 0:
                return .success(false)
            case 1:
                return .success(true)
            default:
                return .failure(ALPH.SerdeError.wrongFormat(message: "Invalid boolean value"))
            }
        }
    }

    struct ByteSerde: FixedSizeSerde {
        func serialize(_ input: UInt8) -> Data {
            return Data([input])
        }

        func deserialize(_ input: Data) -> Result<UInt8, Error> {
            guard let firstByte = input.first else {
                return .failure(ALPH.SerdeError.wrongFormat(message: "Empty input"))
            }
            return .success(firstByte)
        }
    }

    struct IntSerde: FixedSizeSerde {
        func serialize(_ input: Int) -> Data {
            CompactInteger.Signed.encode(input)
        }

        func deserialize(_ input: Data) -> Result<Int, Error> {
            do {
                let result = try CompactInteger.Signed.decodeInt(input).get()
                return .success(result.value)
            } catch {
                return .failure(error)
            }
        }
    }

    struct LongSerde: FixedSizeSerde {
        func serialize(_ input: Int64) -> Data {
            CompactInteger.Signed.encode(input)
        }

        func deserialize(_ input: Data) -> Result<Int64, Error> {
            do {
                let result = try CompactInteger.Signed.decodeLong(input).get()
                return .success(result.value)
            } catch {
                return .failure(error)
            }
        }
    }

    struct U256Serde: FixedSizeSerde {
        func serialize(_ input: U256) -> Data {
            return CompactInteger.Unsigned.encode(input)
        }

        func deserialize(_ input: Data) -> Result<U256, Error> {
            do {
                let result = try CompactInteger.Unsigned.decodeU256(input).get()
                return .success(result.value)
            } catch {
                return .failure(error)
            }
        }
    }

    struct U32Serde: FixedSizeSerde {
        func serialize(_ input: U32) -> Data {
            return CompactInteger.Unsigned.encode(input)
        }

        func deserialize(_ input: Data) -> Result<U32, Error> {
            do {
                let result = try CompactInteger.Unsigned.decodeU32(input).get()
                return .success(result.value)
            } catch {
                return .failure(error)
            }
        }
    }

    struct BytesSerde: FixedSizeSerde {
        var serdeSize: Int { length }

        let length: Int

        func serialize(_ input: Data) -> Data {
            guard input.count == length else {
                return Data()
            }

            return input
        }

        func deserialize(_ input: Data) -> Result<Data, Error> {
            return deserialize0(input: input, f: { $0 })
        }
    }

    struct TimeStampSerde: FixedSizeSerde {
        var serdeSize: Int = MemoryLayout<Int64>.size

        func serialize(_ input: TimeStamp) -> Data {
            Bytes.from(input.millis)
        }

        func deserialize(_ input: Data) -> Result<TimeStamp, any Error> {
            guard input.count >= serdeSize else {
                return .failure(SerdeError.incompleteData(expected: serdeSize, got: input.count))
            }

            let millis = input.prefix(serdeSize).withUnsafeBytes { $0.load(as: Int64.self) }.bigEndian

            guard millis >= 0 else {
                return .failure(SerdeError.validation(message: "Negative timestamp"))
            }

            return .success(TimeStamp(millis))
        }
    }

    struct DataSerde: Serde {
        typealias Value = Data

        func serialize(_ input: Data) -> Data {
            var output = Data()
            output.append(IntSerde().serialize(input.count))
            output.append(input)
            return output
        }

        func _deserialize(_ input: Data) -> Result<ALPH.Staging<Data>, Error> {
            do {
                let deserialize = try IntSerde()._deserialize(input).get()

                guard deserialize.value >= 0 else {
                    return .failure(SerdeError.validation(message: "Negative byte string length: \(deserialize.value)"))
                }

                guard deserialize.rest.count >= deserialize.value else {
                    return .failure(SerdeError.incompleteData(expected: deserialize.value, got: deserialize.rest.count))
                }

                let value = deserialize.rest.prefix(deserialize.value)
                let remaining = deserialize.rest.dropFirst(deserialize.value)
                return .success(Staging(value: value, rest: remaining))
            } catch {
                return .failure(error)
            }
        }
    }
}
