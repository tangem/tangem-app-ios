//
//  MainQRParserSupport.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

enum MainQRParserSupport {
    static func queryItems(from value: String) -> [URLQueryItem] {
        guard let querySeparator = value.firstIndex(of: "?") else {
            return []
        }

        let rawQuery = String(value[value.index(after: querySeparator)...])
        return queryItems(fromRawQuery: rawQuery)
    }

    static func queryItems(fromRawQuery rawQuery: String) -> [URLQueryItem] {
        rawQuery
            .split(separator: "&")
            .compactMap { pair in
                let parts = pair.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
                guard let rawName = parts.first else {
                    return nil
                }

                let name = normalizeQueryKey(String(rawName))
                let value = parts.count > 1 ? String(parts[1]).removingPercentEncoding : nil
                return URLQueryItem(name: name, value: value)
            }
    }

    static func firstQueryValue(in queryItems: [URLQueryItem], names: [String]) -> String? {
        let normalizedNames = Set(names.map(normalizeQueryKey))
        return queryItems.first(where: { normalizedNames.contains(normalizeQueryKey($0.name)) })?.value
    }

    static func firstPayloadString(in payload: [String: Any], keys: [String]) -> String? {
        for key in keys {
            if let value = payload[key] as? String {
                return value
            }
        }

        return nil
    }

    static func normalizeIdentifier(_ string: String) -> String {
        string
            .lowercased()
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: " ", with: "")
    }

    static func normalizeQueryKey(_ name: String) -> String {
        name.lowercased()
    }

    static func hasPrefix(_ value: String, in prefixes: [String]) -> Bool {
        let lowercasedValue = value.lowercased()
        return prefixes.contains { lowercasedValue.hasPrefix($0.lowercased()) }
    }

    static func stripEthereumSchemePrefix(from value: String) -> String? {
        let lowercasedValue = value.lowercased()
        let ethereumPrefixes = Blockchain.ethereum(testnet: false).qrPrefixes
            .sorted(by: { $0.count > $1.count })
        guard let prefix = ethereumPrefixes.first(where: { lowercasedValue.hasPrefix($0.lowercased()) }) else {
            return nil
        }

        return String(value.dropFirst(prefix.count))
    }
}
