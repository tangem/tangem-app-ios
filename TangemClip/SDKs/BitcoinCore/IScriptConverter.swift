//
//  IScriptConverter.swift
//  TangemClip
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

public class Chunk: Equatable {
    let scriptData: Data
    let index: Int
    let payloadRange: Range<Int>?

    public var opCode: UInt8 { return scriptData[index] }
    public var data: Data? {
        guard let payloadRange = payloadRange, scriptData.count >= payloadRange.upperBound else {
            return nil
        }
        return scriptData.subdata(in: payloadRange)
    }

    public init(scriptData: Data, index: Int, payloadRange: Range<Int>? = nil) {
        self.scriptData = scriptData
        self.index = index
        self.payloadRange = payloadRange
    }

    static public func ==(lhs: Chunk, rhs: Chunk) -> Bool {
        return lhs.scriptData == rhs.scriptData && lhs.opCode == rhs.opCode && lhs.payloadRange == rhs.payloadRange
    }

}

public class Script {
    public let scriptData: Data
    public let chunks: [Chunk]

    public var length: Int { return scriptData.count }

    public func validate(opCodes: Data) throws {
        guard opCodes.count == chunks.count else {
            throw BitcoinCoreScriptError.wrongScriptLength
        }
        try chunks.enumerated().forEach { (index, chunk) in
            if chunk.opCode != opCodes[index] {
                throw BitcoinCoreScriptError.wrongSequence
            }
        }
    }

    public init(with data: Data, chunks: [Chunk]) {
        self.scriptData = data
        self.chunks = chunks
    }

}

public protocol IScriptConverter {
    func decode(data: Data) throws -> Script
}

enum BitcoinCoreScriptError: Error { case wrongScriptLength, wrongSequence }

public class ScriptConverter {

    public init() {}

    public func encode(script: Script) -> Data {
        var scriptData = Data()
        script.chunks.forEach { chunk in
            if let data = chunk.data {
                scriptData += OpCode.push(data)
            } else {
                scriptData += Data([chunk.opCode])
            }
        }
        return scriptData
    }

    private func getPushRange(data: Data, it: Int) throws -> Range<Int> {
        let opCode = data[it]

        var bytesCount: Int?
        var bytesOffset = 1
        switch opCode {
        case 0x01..<OpCode.OP_PUSHDATA1.value: bytesCount = Int(opCode)
        case OpCode.OP_PUSHDATA1.value:                              // The next byte contains the number of bytes to be pushed onto the stack
                bytesOffset += 1
                guard data.count > 1 else {
                    throw BitcoinCoreScriptError.wrongScriptLength
                }
                bytesCount = Int(data[1])
        case OpCode.OP_PUSHDATA2.value:                              // The next two bytes contain the number of bytes to be pushed onto the stack in little endian order
                bytesOffset += 2
                guard data.count > 2 else {
                    throw BitcoinCoreScriptError.wrongScriptLength
                }
                bytesCount = Int(data[2]) << 8 + Int(data[1])
        case OpCode.OP_PUSHDATA4.value:                              // The next four bytes contain the number of bytes to be pushed onto the stack in little endian order
                bytesOffset += 4
                guard data.count > 5 else {
                    throw BitcoinCoreScriptError.wrongScriptLength
                }
                var index = bytesOffset
                var count = 0
                while index >= 0 {
                    count += count << 8 + Int(data[1 + index])
                    index -= 1
                }
                bytesCount = count
            default: break
        }
        guard let keyLength = bytesCount, data.count >= it + bytesOffset + keyLength else {
            throw BitcoinCoreScriptError.wrongScriptLength
        }
        return Range(uncheckedBounds: (lower: it + bytesOffset, upper: it + bytesOffset + keyLength))
    }

}

extension ScriptConverter: IScriptConverter {

    public func decode(data: Data) throws -> Script {
        var chunks = [Chunk]()
        var it = 0
        while it < data.count {
            let opCode = data[it]
            switch opCode {
            case 0x01...OpCode.OP_PUSHDATA4.value:
                let range = try getPushRange(data: data, it: it)
                chunks.append(Chunk(scriptData: data, index: it, payloadRange: range))
                it = range.upperBound
            default:
                chunks.append(Chunk(scriptData: data, index: it, payloadRange: nil))
                it += 1
            }
        }
        return Script(with: data, chunks: chunks)
    }

}
