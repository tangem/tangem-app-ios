//
//  SafeContractResponseDecoder.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Reads the answers of a Safe's view methods off the ABI-encoded `eth_call` payload.
enum SafeContractResponseDecoder {
    enum DecodingError: Error {
        case malformedResponse
    }

    /// An `eth_call` to an address without code answers with an empty payload, which is how an undeployed Safe
    /// is told apart from a deployed one at nonce zero.
    static func hasCode(_ response: String) -> Bool {
        !Data(hexString: response).isEmpty
    }

    static func nonce(from response: String) throws -> Int {
        try EthereumMapper.mapInt(response)
    }

    static func threshold(from response: String) throws -> Int {
        try EthereumMapper.mapInt(response)
    }

    /// `address[]`: the first word points at the array, the word there is its length, then one right-aligned
    /// address per word.
    static func owners(from response: String) throws -> [String] {
        let words = try words(from: response)

        guard let offsetWord = words.first,
              let offset = Int(offsetWord, radix: 16),
              offset % Constants.wordLength == 0 else {
            throw DecodingError.malformedResponse
        }

        let lengthIndex = offset / Constants.wordLength

        guard lengthIndex < words.count,
              let count = Int(words[lengthIndex], radix: 16),
              lengthIndex + count < words.count else {
            throw DecodingError.malformedResponse
        }

        guard count > 0 else {
            return []
        }

        return words[(lengthIndex + 1) ... (lengthIndex + count)].map { word in
            "0x" + word.suffix(Constants.addressHexLength)
        }
    }

    private static func words(from response: String) throws -> [String] {
        let hex = response.removeHexPrefix()

        guard !hex.isEmpty, hex.count % Constants.wordHexLength == 0 else {
            throw DecodingError.malformedResponse
        }

        return stride(from: 0, to: hex.count, by: Constants.wordHexLength).map { start in
            let lower = hex.index(hex.startIndex, offsetBy: start)
            let upper = hex.index(lower, offsetBy: Constants.wordHexLength)
            return String(hex[lower ..< upper])
        }
    }

    private enum Constants {
        static let wordLength = 32
        static let wordHexLength = 64
        static let addressHexLength = 40
    }
}
