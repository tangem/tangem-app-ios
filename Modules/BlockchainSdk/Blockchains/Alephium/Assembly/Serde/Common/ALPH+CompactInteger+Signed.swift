//
//  ALPH+CompactInteger+Signed.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension ALPH.CompactInteger {
    enum Signed {
        private static let signFlag: Int = 0x20 // 0b00100000
        private static let oneByteBound: Int = 0x20 // 0b00100000
        private static let twoByteBound: Int = oneByteBound << 8
        private static let fourByteBound: Int = oneByteBound << (8 * 3)

        static func encode(_ n: Int) -> Data {
            return n >= 0 ? encodePositiveInt(n) : encodeNegativeInt(n)
        }

        private static func encodePositiveInt(_ n: Int) -> Data {
            let array: [UInt8]

            switch n {
            case ..<oneByteBound:
                array = [UInt8(truncatingIfNeeded: n + ALPH.SingleByte.prefix)]
            case ..<twoByteBound:
                array = [
                    UInt8(truncatingIfNeeded: (n >> 8) + ALPH.TwoByte.prefix),
                    UInt8(truncatingIfNeeded: n),
                ]
            case ..<fourByteBound:
                array = [
                    UInt8(truncatingIfNeeded: (n >> 24) + ALPH.FourByte.prefix),
                    UInt8(truncatingIfNeeded: n >> 16),
                    UInt8(truncatingIfNeeded: n >> 8),
                    UInt8(truncatingIfNeeded: n),
                ]
            default:
                array = [
                    UInt8(ALPH.MultiByte.prefix),
                    UInt8(truncatingIfNeeded: n >> 24),
                    UInt8(truncatingIfNeeded: n >> 16),
                    UInt8(truncatingIfNeeded: n >> 8),
                    UInt8(truncatingIfNeeded: n),
                ]
            }
            return Data(array)
        }

        private static func encodeNegativeInt(_ n: Int) -> Data {
            let array: [UInt8]
            switch n {
            case (-oneByteBound)...:
                array = [UInt8(UInt8(n) ^ UInt8(ALPH.SingleByte.negPrefix))]
            case (-twoByteBound)...:
                array = [UInt8((UInt8(n) >> 8) ^ UInt8(ALPH.TwoByte.negPrefix)), UInt8(n)]
            case (-fourByteBound)...:
                array = [
                    UInt8((n >> 24) ^ ALPH.FourByte.negPrefix),
                    UInt8(n >> 16),
                    UInt8(n >> 8),
                    UInt8(n),
                ]
            default:
                array = [
                    UInt8(ALPH.MultiByte.prefix),
                    UInt8(n >> 24),
                    UInt8(n >> 16),
                    UInt8(n >> 8),
                    UInt8(n),
                ]
            }
            return Data(array)
        }

        static func encode(_ n: Int64) -> Data {
            if n >= -0x20000000, n < 0x20000000 {
                return encode(Int(n))
            } else {
                let array: [UInt8] = [
                    UInt8(4 | ALPH.MultiByte.prefix),
                    UInt8(n >> 56),
                    UInt8(n >> 48),
                    UInt8(n >> 40),
                    UInt8(n >> 32),
                    UInt8(n >> 24),
                    UInt8(n >> 16),
                    UInt8(n >> 8),
                    UInt8(n),
                ]
                return Data(array)
            }
        }

        static func decodeInt(_ data: Data) -> Result<ALPH.Staging<Int>, Error> {
            switch ALPH.ModeUtils.decode(data) {
            case .success(let (mode, body, rest)):
                return decodeInt(mode, body, rest)
            case .failure(let error):
                return .failure(error)
            }
        }

        private static func decodeInt(
            _ mode: ALPH.Mode,
            _ body: Data,
            _ rest: Data
        ) -> Result<ALPH.Staging<Int>, Error> {
            switch mode {
            case is ALPH.FixedWidth:
                guard let mode = mode as? ALPH.FixedWidth else {
                    return .failure(ALPH.SerdeError.wrongFormat(message: "Unknown mode"))
                }

                return decodeFixedWidthInt(mode, body, rest)
            case is ALPH.MultiByte:
                guard body.count >= 5 else {
                    return .failure(ALPH.SerdeError.wrongFormat(message: "Expect 4 bytes int, but got \(body.count - 1) bytes int"))
                }

                let value = Int(ALPH.Bytes.toIntUnsafe(body.dropFirst()))
                return .success(ALPH.Staging(value: value, rest: rest))
            default:
                return .failure(ALPH.SerdeError.wrongFormat(message: "Unknown mode"))
            }
        }

        private static func decodeFixedWidthInt(
            _ mode: ALPH.FixedWidth,
            _ body: Data,
            _ rest: Data
        ) -> Result<ALPH.Staging<Int>, Error> {
            let isPositive = (Int(body[0]) & signFlag) == 0
            return isPositive ? decodePositiveInt(mode, body, rest) : decodeNegativeInt(mode, body, rest)
        }

        private static func decodePositiveInt(
            _ mode: ALPH.FixedWidth,
            _ body: Data,
            _ rest: Data
        ) -> Result<ALPH.Staging<Int>, Error> {
            switch mode {
            case is ALPH.SingleByte:
                guard body.count == 1 else {
                    return .failure(ALPH.SerdeError.wrongFormat(message: "Invalid size for OneByte"))
                }

                return .success(ALPH.Staging(value: Int(body[0]), rest: rest))
            case is ALPH.TwoByte:
                guard body.count == 2 else {
                    return .failure(ALPH.SerdeError.wrongFormat(message: "Invalid size for TwoByte"))
                }

                let value = ((body[0] & UInt8(ALPH.ModeUtils.maskMode)) << 8) | body[1]
                return .success(ALPH.Staging(value: Int(value), rest: rest))
            case is ALPH.FourByte:
                guard body.count == 4 else {
                    return .failure(ALPH.SerdeError.wrongFormat(message: "Invalid size for FourByte"))
                }

                let value = ((UInt8(body[0]) & UInt8(ALPH.ModeUtils.maskMode)) << 24) |
                    (UInt8(body[1]) << 16) |
                    (UInt8(body[2]) << 8) |
                    UInt8(body[3])
                return .success(ALPH.Staging(value: Int(value), rest: rest))
            default:
                return .failure(ALPH.SerdeError.wrongFormat(message: "Unknown mode"))
            }
        }

        private static func decodeNegativeInt(
            _ mode: ALPH.FixedWidth,
            _ body: Data,
            _ rest: Data
        ) -> Result<ALPH.Staging<Int>, Error> {
            switch mode {
            case is ALPH.SingleByte:
                return .success(ALPH.Staging(value: Int(body[0]) | ALPH.ModeUtils.maskModeNeg, rest: rest))
            case is ALPH.TwoByte:
                guard body.count == 2 else {
                    return .failure(ALPH.SerdeError.wrongFormat(message: "Invalid size for TwoByte"))
                }

                let value = ((Int(body[0]) | ALPH.ModeUtils.maskModeNeg) << 8) | Int(body[1])
                return .success(ALPH.Staging(value: value, rest: rest))
            case is ALPH.FourByte:
                guard body.count == 4 else {
                    return .failure(ALPH.SerdeError.wrongFormat(message: "Invalid size for FourByte"))
                }

                let value = ((Int(body[0]) | ALPH.ModeUtils.maskModeNeg) << 24) |
                    (Int(body[1]) << 16) |
                    (Int(body[2]) << 8) |
                    Int(body[3])

                return .success(ALPH.Staging(value: value, rest: rest))
            default:
                return .failure(ALPH.SerdeError.wrongFormat(message: "Unknown mode"))
            }
        }

        static func decodeLong(_ data: Data) -> Result<ALPH.Staging<Int64>, Error> {
            switch ALPH.ModeUtils.decode(data) {
            case .success(let (mode, body, rest)):
                return decodeLong(mode, body, rest)
            case .failure(let error):
                return .failure(error)
            }
        }

        private static func decodeLong(
            _ mode: ALPH.Mode,
            _ body: Data,
            _ rest: Data
        ) -> Result<ALPH.Staging<Int64>, Error> {
            switch mode {
            case is ALPH.FixedWidth:
                guard let mode = mode as? ALPH.FixedWidth else {
                    return .failure(ALPH.SerdeError.wrongFormat(message: "Unknown mode"))
                }

                return decodeFixedWidthInt(mode, body, rest).map { staging in
                    ALPH.Staging(value: Int64(staging.value), rest: staging.rest)
                }
            case is ALPH.MultiByte:
                guard body.count >= 5, body.count == 9 else {
                    return .failure(ALPH.SerdeError.wrongFormat(message: "Expect 9 bytes long, but got \(body.count - 1) bytes long"))
                }
                let value = ALPH.Bytes.toLongUnsafe(body.dropFirst())
                return .success(ALPH.Staging(value: value, rest: rest))
            default:
                return .failure(ALPH.SerdeError.wrongFormat(message: "Unknown mode"))
            }
        }
    }
}
