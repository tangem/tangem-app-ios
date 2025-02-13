//
//  ALPH+CompactInteger+Unsigned.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

extension ALPH.CompactInteger {
    enum Unsigned {
        private static let oneByteBound: ALPH.U32 = .init(v: 0x40)
        private static let twoByteBound: ALPH.U32 = .init(v: 0x40 << 8)
        private static let fourByteBound: ALPH.U32 = .init(v: 0x40 << (8 * 3))

        static func encode(_ n: ALPH.U32) -> Data {
            var data = Data()
            let v = n.v

            switch v {
            case 0 ..< oneByteBound.v:
                data.append(UInt8(v))
            case 0 ..< twoByteBound.v:
                data.append(UInt8((v >> 8) + 0x40))
                data.append(UInt8(v & 0xFF))
            case 0 ..< fourByteBound.v:
                data.append(UInt8((v >> 24) + 0x80))
                data.append(UInt8((v >> 16) & 0xFF))
                data.append(UInt8((v >> 8) & 0xFF))
                data.append(UInt8(v & 0xFF))
            default:
                data.append(0xC0)
                data.append(contentsOf: withUnsafeBytes(of: v.bigEndian) { Data($0) })
            }
            return data
        }

        static func encode(_ n: ALPH.U256) -> Data {
            if n < ALPH.U256.unsafe(BigUInt(fourByteBound.v)) {
                return encode(ALPH.U32.from(n.v) ?? .Zero)
            } else {
                var data = n.v.serialize()
                if data.first == 0x00 {
                    data = data.dropFirst()
                }

                let prefix = ALPH.MultiByte.prefix
                let header = UInt8((data.count - 4) + Int(prefix))

                return Data([header]) + data
            }
        }

        static func decodeU32(_ data: Data) -> Result<ALPH.Staging<ALPH.U32>, Error> {
            switch ALPH.ModeUtils.decode(data) {
            case .success(let (mode, body, rest)):
                return decodeU32(mode: mode, body: body, rest: rest)
            case .failure(let error):
                return .failure(error)
            }
        }

        private static func decodeU32(mode: ALPH.Mode, body: Data, rest: Data) -> Result<ALPH.Staging<ALPH.U32>, Error> {
            switch mode {
            case is ALPH.FixedWidth:
                guard let mode = mode as? ALPH.FixedWidth else {
                    return .failure(ALPH.SerdeError.wrongFormat(message: "Unknown mode in decodeU32"))
                }

                return decodeInt(mode: mode, body: body, rest: rest).map { staging in
                    ALPH.Staging(value: ALPH.U32.unsafe(UInt32(staging.value)), rest: staging.rest)
                }

            case is ALPH.MultiByte:
                guard body.count >= 5 else {
                    return .failure(ALPH.SerdeError.wrongFormat(message: "Expect 4 bytes int, but got \(body.count - 1) bytes int"))
                }
                if body.count == 5 {
                    let value = ALPH.Bytes.toIntUnsafe(body.subdata(in: 1 ..< body.count))
                    return .success(ALPH.Staging(value: ALPH.U32.unsafe(UInt32(value)), rest: rest))
                } else {
                    return .failure(ALPH.SerdeError.wrongFormat(message: "Expect 4 bytes int, but got \(body.count - 1) bytes int"))
                }

            default:
                return .failure(ALPH.SerdeError.wrongFormat(message: "Unknown mode in decodeU32"))
            }
        }

        private static func decodeInt(mode: ALPH.FixedWidth, body: Data, rest: Data) -> Result<ALPH.Staging<Int>, Error> {
            switch mode {
            case is ALPH.SingleByte:
                guard let firstByte = body.first else {
                    return .failure(ALPH.SerdeError.wrongFormat(message: "Expected single byte but got empty body"))
                }
                return .success(ALPH.Staging(value: Int(firstByte), rest: rest))

            case is ALPH.TwoByte:
                guard body.count == 2 else {
                    return .failure(ALPH.SerdeError.wrongFormat(message: "Expected 2 bytes but got \(body.count) bytes"))
                }

                let lvalue = Int(Int(body[0]) & ALPH.ModeUtils.maskMode) << 8
                let rvalue = Int(body[1] & 0xff)
                let value = lvalue | rvalue

                return .success(ALPH.Staging(value: value, rest: rest))

            case is ALPH.FourByte:
                guard body.count == 4 else {
                    return .failure(ALPH.SerdeError.wrongFormat(message: "Expected 4 bytes but got \(body.count) bytes"))
                }
                let value = (Int(Int(body[0]) & ALPH.ModeUtils.maskMode) << 24) |
                    (Int(body[1] & 0xff) << 16) |
                    (Int(body[2] & 0xff) << 8) |
                    Int(body[3] & 0xff)
                return .success(ALPH.Staging(value: value, rest: rest))

            default:
                return .failure(ALPH.SerdeError.wrongFormat(message: "Unknown mode in decodeInt"))
            }
        }

        static func decodeU256(_ data: Data) -> Result<ALPH.Staging<ALPH.U256>, Error> {
            switch ALPH.ModeUtils.decode(data) {
            case .success(let (mode, body, rest)):
                return decodeU256(mode: mode, body: body, rest: rest)
            case .failure(let error):
                return .failure(error)
            }
        }

        private static func decodeU256(mode: ALPH.Mode, body: Data, rest: Data) -> Result<ALPH.Staging<ALPH.U256>, Error> {
            switch mode {
            case is ALPH.FixedWidth:
                guard let mode = mode as? ALPH.FixedWidth else {
                    return .failure(ALPH.SerdeError.wrongFormat(message: "Unknown mode in decodeInt"))
                }

                return decodeInt(mode: mode, body: body, rest: rest).map { staging in
                    ALPH.Staging(value: ALPH.U256.unsafe(BigUInt(staging.value)), rest: staging.rest)
                }

            case is ALPH.MultiByte:
                guard body.count >= 2 else {
                    return .failure(ALPH.SerdeError.wrongFormat(message: "Expect U256, but got insufficient bytes"))
                }
                if let value = ALPH.U256.from(body.subdata(in: 1 ..< body.count)) {
                    return .success(ALPH.Staging(value: value, rest: rest))
                } else {
                    return .failure(ALPH.SerdeError.wrongFormat(message: "Expect U256, but got corrupted data"))
                }

            default:
                return .failure(ALPH.SerdeError.wrongFormat(message: "Unknown mode in decodeU256"))
            }
        }
    }
}
