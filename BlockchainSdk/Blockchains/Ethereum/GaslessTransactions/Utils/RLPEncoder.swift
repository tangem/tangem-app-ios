//
//  RLPEncoder.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// https://github.com/alephao/swift-rlp
struct RLPEncoder: Sendable {
    // MARK: - Properties

    private let encoding: String.Encoding = .utf8

    // MARK: - Public Implementation

    func encode(_ input: RLPValue) throws(RLPError) -> Data {
        switch input {
        case .string(let str):
            return try encode(string: str)

        case .bytes(let data):
            return encode(bytes: data)

        case .array(let arr):
            var output = Data()
            for value in arr {
                output.append(try encode(value))
            }
            return encodeLength(UInt(output.count), offset: 0xc0) + output
        }
    }

    func encode(string input: String) throws(RLPError) -> Data {
        guard let strData = input.data(using: encoding) else {
            throw .stringToData(input)
        }

        if strData.count == 1, strData.first! < 0x80 {
            return strData
        }

        return encodeLength(UInt(strData.count), offset: 0x80) + strData
    }

    func encode(bytes data: Data) -> Data {
        if data.count == 1, let b = data.first, b < 0x80 { return data }
        return encodeLength(UInt(data.count), offset: 0x80) + data
    }

    // MARK: - Private Implementation

    private func toBinary(_ x: UInt) -> Data {
        if x == 0 {
            return Data()
        }

        let (q, r) = x.quotientAndRemainder(dividingBy: 256)

        return toBinary(q) + Data([UInt8(r)])
    }

    private func encodeLength(_ length: UInt, offset: UInt8) -> Data {
        if length < 56 {
            let lengthByte = offset + UInt8(length)
            return Data([lengthByte])
        }

        let binaryLength = toBinary(length)
        return Data([UInt8(UInt(binaryLength.count) + UInt(offset) + 55)]) + binaryLength
    }
}

enum RLPValue: Equatable, Sendable {
    case string(String)
    case bytes(Data)
    case array([RLPValue])
}

enum RLPError: Error {
    case stringToData(String)
    case dataToString
    case invalidObject(ofType: Any.Type, expected: Any.Type)

    var localizedDescription: String {
        switch self {
        case .stringToData(let str): return "Failed to convert String to Data: \"\(str)\""
        case .dataToString: return "Failed to convert Data to String"
        case .invalidObject(let got, let expected): return "Invalid object, expected \(expected), but got \(got)"
        }
    }
}
