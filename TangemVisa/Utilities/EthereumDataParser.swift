//
//  ParserUtilities.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct EthereumDataParser {
    private static let defaultChunkLength = 64

    func split(string: String, chunkLength: Int = defaultChunkLength) -> [String] {
        var startIndex = string.startIndex
        var results = [Substring]()

        while startIndex < string.endIndex {
            let endIndex = string.index(startIndex, offsetBy: chunkLength, limitedBy: string.endIndex) ?? string.endIndex
            results.append(string[startIndex ..< endIndex])
            startIndex = endIndex
        }

        return results.map { String($0) }
    }

    func getData(string: String) -> Data {
        Data(hexString: string)
    }

    func getDecimal(string: String, decimalsCount: Int, defaultDecimal: Decimal = 0) -> Decimal {
        EthereumUtils.parseEthereumDecimal(string, decimalsCount: decimalsCount) ?? defaultDecimal
    }

    func getTimeInSeconds(string: String, defaultTimeIfEmpty: Double = 0) -> Double {
        EthereumUtils.parseEthereumDecimal(string, decimalsCount: 0)?.doubleValue ?? defaultTimeIfEmpty
    }

    func getDateSince1970(string: String, defaultDataIfEmpty: Date = Date(timeIntervalSince1970: 0)) -> Date {
        guard
            let timeInterval = EthereumUtils.parseEthereumDecimal(string, decimalsCount: 0)?.doubleValue
        else {
            return defaultDataIfEmpty
        }

        return Date(timeIntervalSince1970: timeInterval)
    }

    func getBool(string: String) -> Bool {
        guard !string.isEmpty else {
            return false
        }

        return string.last! == "1"
    }
}
