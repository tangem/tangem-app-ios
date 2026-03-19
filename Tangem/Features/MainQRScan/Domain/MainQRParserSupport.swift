//
//  MainQRParserSupport.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation

enum MainQRParserSupport {
    static func resolveEVMBlockchain(chainId: Int?) -> Blockchain? {
        guard let chainId else {
            return nil
        }

        return Blockchain.allMainnetCases.first(where: { $0.chainId == chainId })
    }

    static func extractChainIdRawValue(fromPath path: String) -> String? {
        guard let atIndex = path.firstIndex(of: "@") else {
            return nil
        }

        let chainPart = path[path.index(after: atIndex)...]
        return chainPart
            .split(separator: "/", maxSplits: 1, omittingEmptySubsequences: false)
            .first
            .map(String.init)
    }

    static func stripChainId(_ path: String) -> String {
        guard let atIndex = path.firstIndex(of: "@") else {
            return path
        }

        let addressPart = String(path[..<atIndex])
        let afterChainPart = path[path.index(after: atIndex)...]
        let remainder = afterChainPart.split(separator: "/", maxSplits: 1, omittingEmptySubsequences: false)

        guard remainder.count > 1 else {
            return addressPart
        }

        return "\(addressPart)/\(remainder[1])"
    }

    static func resolveBlockchain(fromChainName chainName: String) -> Blockchain? {
        let normalized = normalize(chainName)

        switch normalized {
        case "eth", "ethereum":
            return .ethereum(testnet: false)
        case "bnb", "bsc", "bnbchain", "binancesmartchain":
            return .bsc(testnet: false)
        case "polygon", "matic":
            return .polygon(testnet: false)
        case "btc", "bitcoin":
            return .bitcoin(testnet: false)
        case "trx", "tron":
            return .tron(testnet: false)
        case "sol", "solana":
            return .solana(curve: .ed25519_slip0010, testnet: false)
        case "ton", "theopennetwork":
            return .ton(curve: .ed25519_slip0010, testnet: false)
        default:
            break
        }

        return Blockchain.allMainnetCases.first { blockchain in
            normalize(blockchain.codingKey) == normalized
                || normalize(blockchain.displayName) == normalized
                || normalize(blockchain.currencySymbol) == normalized
        }
    }

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

                let name = normalizeQueryName(String(rawName))
                let value = parts.count > 1 ? String(parts[1]).removingPercentEncoding : nil
                return URLQueryItem(name: name, value: value)
            }
    }

    static func parseDecimal(_ string: String) -> Decimal? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        let decimalSeparator = Locale.posixEnUS.decimalSeparator ?? "."
        let normalized = normalizeDecimalSeparators(in: trimmed, decimalSeparator: decimalSeparator)

        guard isStrictDecimalString(normalized, decimalSeparator: decimalSeparator) else {
            return nil
        }

        return Decimal(string: normalized, locale: .posixEnUS)
    }

    static func normalizeDecimalSeparators(in string: String, decimalSeparator: String) -> String {
        string.replacingOccurrences(of: ",", with: decimalSeparator)
    }

    static func isStrictDecimalString(_ string: String, decimalSeparator: String) -> Bool {
        let escapedSeparator = NSRegularExpression.escapedPattern(for: decimalSeparator)
        let pattern = "^[+-]?(?:\\d+(?:\(escapedSeparator)\\d+)?|\(escapedSeparator)\\d+)(?:[eE][+-]?\\d+)?$"
        return string.range(of: pattern, options: .regularExpression) != nil
    }

    static func isValidDestinationAddress(_ address: String, for blockchain: Blockchain) -> Bool {
        let addressService = AddressServiceFactory(blockchain: blockchain).makeAddressService()
        return addressService.validate(address)
    }

    static func normalize(_ string: String) -> String {
        string
            .lowercased()
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: " ", with: "")
    }

    static func normalizeQueryName(_ name: String) -> String {
        name.lowercased()
    }

    static func firstQueryValue(in queryItems: [URLQueryItem], names: [String]) -> String? {
        let normalizedNames = Set(names.map(normalizeQueryName))
        return queryItems.first(where: { normalizedNames.contains(normalizeQueryName($0.name)) })?.value
    }

    static func firstPayloadString(in payload: [String: Any], keys: [String]) -> String? {
        for key in keys {
            if let value = payload[key] as? String {
                return value
            }
        }

        return nil
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
