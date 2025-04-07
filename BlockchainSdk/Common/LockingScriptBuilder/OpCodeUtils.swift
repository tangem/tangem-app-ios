//
//  OpCodeUtils.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum OpCodeUtils {
    static func p2pk(data: Data) -> Data {
        var script = Data()
        script.append(OpCode.push(data))
        script.append(OpCode.OP_CHECKSIG.value)
        return script
    }

    /// Kaspa specific
    static func p2pkECDSA(data: Data) -> Data {
        var script = Data()
        script.append(OpCode.push(data))
        script.append(OpCode.OP_CODESEPARATOR.value)
        return script
    }

    static func p2pkh(data: Data) -> Data {
        var script = Data()
        script.append(OpCode.OP_DUP.value)
        script.append(OpCode.OP_HASH160.value)
        script.append(OpCode.push(data))
        script.append(OpCode.OP_EQUALVERIFY.value)
        script.append(OpCode.OP_CHECKSIG.value)
        return script
    }

    static func p2sh(data: Data) -> Data {
        var script = Data()
        script.append(OpCode.OP_HASH160.value)
        script.append(OpCode.push(data))
        script.append(OpCode.OP_EQUAL.value)
        return script
    }

    /// Kaspa specific
    static func p2sh256(data: Data) -> Data {
        var script = Data()
        script.append(OpCode.OP_HASH256.value)
        script.append(OpCode.push(data))
        script.append(OpCode.OP_EQUAL.value)
        return script
    }

    static func p2wpkh(version: UInt8, data: Data) -> Data {
        OpCode.push(version) + OpCode.push(data)
    }

    static func p2wsh(version: UInt8, data: Data) -> Data {
        OpCode.push(version) + OpCode.push(data)
    }

    static func p2tr(version: UInt8, data: Data) -> Data {
        OpCode.push(version) + OpCode.push(data)
    }
}

extension OpCode {
    static func push(_ value: UInt8) -> Data {
        guard value > 0 else {
            return Data([0])
        }

        guard value <= 16 else {
            return Data()
        }

        return Data([UInt8(value + 0x50)])
    }

    static func push(_ data: Data) -> Data {
        let length = data.count
        var bytes = Data()

        switch length {
        case 0x00 ... 0x4b: bytes = Data([UInt8(length)])
        case 0x4c ... 0xff: bytes = Data([OpCode.OP_PUSHDATA1.value]) + Data(UInt8(length).littleEndian)
        case 0x0100 ... 0xffff: bytes = Data([OpCode.OP_PUSHDATA2.value]) + UInt16(length).littleEndian.data
        case 0x10000 ... 0xffffffff: bytes = Data([OpCode.OP_PUSHDATA4.value]) + UInt32(length).littleEndian.data
        default: return data
        }

        return bytes + data
    }
}
