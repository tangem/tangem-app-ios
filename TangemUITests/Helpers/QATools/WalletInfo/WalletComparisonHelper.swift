//
//  WalletComparisonHelper.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import XCTest

struct WalletComparisonResult {
    let differences: [WalletDifference]
    let errorMessage: String

    var hasDifferences: Bool {
        !differences.isEmpty
    }
}

struct WalletDifference {
    let type: DifferenceType
    let field: String?
    let uiValue: String?
    let apiValue: String?
    let walletKey: String
    let walletIdentifier: String

    enum DifferenceType {
        case countMismatch
        case missingInAPI
        case missingInUI
        case fieldMismatch
    }
}

enum WalletComparisonHelper {
    static func compare(uiWallets: [WalletInfoJSON], apiWallets: [WalletInfoJSON]) -> WalletComparisonResult {
        let differences = compareWallets(uiWallets: uiWallets, apiWallets: apiWallets)
        let errorMessage = buildComparisonErrorMessage(differences: differences)

        // Log successful comparison for Allure if no differences found
        if differences.isEmpty {
            XCTContext.runActivity(named: "✅ All addresses match successfully") { _ in }
        }

        return WalletComparisonResult(differences: differences, errorMessage: errorMessage)
    }

    // MARK: - Private Helpers

    private static func walletKey(for wallet: WalletInfoJSON) -> String {
        // Create unique key: blockchain + derivationPath + token (if present)
        var key = "\(wallet.blockchain)|\(wallet.derivationPath)"
        if let token = wallet.token, !token.isEmpty {
            key += "|\(token)"
        }
        return key
    }

    private static func walletIdentifier(for wallet: WalletInfoJSON) -> String {
        var identifier = wallet.blockchain
        if let token = wallet.token, !token.isEmpty {
            identifier += " (\(token))"
        }
        identifier += " - \(wallet.derivationPath)"
        return identifier
    }

    private static func compareWallets(uiWallets: [WalletInfoJSON], apiWallets: [WalletInfoJSON]) -> [WalletDifference] {
        var differences: [WalletDifference] = []

        // Check count mismatch
        if uiWallets.count != apiWallets.count {
            differences.append(WalletDifference(
                type: .countMismatch,
                field: nil,
                uiValue: "\(uiWallets.count)",
                apiValue: "\(apiWallets.count)",
                walletKey: "",
                walletIdentifier: ""
            ))
        }

        // Convert arrays to dictionaries with unique keys
        var uiWalletsDict: [String: WalletInfoJSON] = [:]
        for wallet in uiWallets {
            let key = walletKey(for: wallet)
            uiWalletsDict[key] = wallet
        }

        var apiWalletsDict: [String: WalletInfoJSON] = [:]
        for wallet in apiWallets {
            let key = walletKey(for: wallet)
            apiWalletsDict[key] = wallet
        }

        // Get all unique keys from both dictionaries
        let allKeys = Set(uiWalletsDict.keys).union(Set(apiWalletsDict.keys))

        // Compare wallets by unique keys
        for key in allKeys.sorted() {
            let uiWallet = uiWalletsDict[key]
            let apiWallet = apiWalletsDict[key]

            // Wallet present only in UI
            if let uiWallet = uiWallet, apiWallet == nil {
                let identifier = walletIdentifier(for: uiWallet)
                differences.append(WalletDifference(
                    type: .missingInAPI,
                    field: nil,
                    uiValue: identifier,
                    apiValue: nil,
                    walletKey: key,
                    walletIdentifier: identifier
                ))
                continue
            }

            // Wallet present only in API
            if let apiWallet = apiWallet, uiWallet == nil {
                let identifier = walletIdentifier(for: apiWallet)
                differences.append(WalletDifference(
                    type: .missingInUI,
                    field: nil,
                    uiValue: nil,
                    apiValue: identifier,
                    walletKey: key,
                    walletIdentifier: identifier
                ))
                continue
            }

            // Both wallets exist - compare fields
            guard let uiWallet = uiWallet, let apiWallet = apiWallet else {
                continue
            }

            let identifier = walletIdentifier(for: uiWallet)

            // Compare addresses
            if uiWallet.addresses != apiWallet.addresses {
                let uiAddresses = formatAddresses(uiWallet.addresses)
                let apiAddresses = formatAddresses(apiWallet.addresses)

                // Log address mismatch for Allure
                XCTContext.runActivity(named: "❌ Addresses mismatch for \(identifier)\nUI: \(uiAddresses)\nAPI: \(apiAddresses)") { _ in }

                differences.append(WalletDifference(
                    type: .fieldMismatch,
                    field: "addresses",
                    uiValue: uiAddresses,
                    apiValue: apiAddresses,
                    walletKey: key,
                    walletIdentifier: identifier
                ))
            }

            // Compare blockchain (should match if key matches, but check anyway)
            if uiWallet.blockchain != apiWallet.blockchain {
                differences.append(WalletDifference(
                    type: .fieldMismatch,
                    field: "blockchain",
                    uiValue: uiWallet.blockchain,
                    apiValue: apiWallet.blockchain,
                    walletKey: key,
                    walletIdentifier: identifier
                ))
            }

            // Compare derivation path
            if uiWallet.derivationPath != apiWallet.derivationPath {
                differences.append(WalletDifference(
                    type: .fieldMismatch,
                    field: "derivationPath",
                    uiValue: uiWallet.derivationPath,
                    apiValue: apiWallet.derivationPath,
                    walletKey: key,
                    walletIdentifier: identifier
                ))
            }

            // Compare token (handle nil values)
            let uiToken = uiWallet.token ?? "nil"
            let apiToken = apiWallet.token ?? "nil"
            if uiToken != apiToken {
                differences.append(WalletDifference(
                    type: .fieldMismatch,
                    field: "token",
                    uiValue: uiToken,
                    apiValue: apiToken,
                    walletKey: key,
                    walletIdentifier: identifier
                ))
            }
        }

        return differences
    }

    private static func formatAddresses(_ addresses: [String]) -> String {
        if addresses.isEmpty {
            return "[]"
        }
        if addresses.count <= 3 {
            return "[\(addresses.joined(separator: ", "))]"
        }
        return "[\(addresses.prefix(3).joined(separator: ", ")), ... (\(addresses.count) total)]"
    }

    private static func buildComparisonErrorMessage(differences: [WalletDifference]) -> String {
        var message = "\n\n=== Wallet Comparison Differences ===\n\n"

        // Group differences by type
        let countMismatches = differences.filter { $0.type == .countMismatch }
        let missingInAPI = differences.filter { $0.type == .missingInAPI }
        let missingInUI = differences.filter { $0.type == .missingInUI }
        let fieldMismatches = differences.filter { $0.type == .fieldMismatch }

        // Count mismatch
        if !countMismatches.isEmpty {
            let diff = countMismatches[0]
            message += "❌ COUNT MISMATCH:\n"
            message += "   UI wallets: \(diff.uiValue ?? "unknown")\n"
            message += "   API wallets: \(diff.apiValue ?? "unknown")\n"
            message += "   Difference: \(abs((Int(diff.uiValue ?? "0") ?? 0) - (Int(diff.apiValue ?? "0") ?? 0)))\n\n"
        }

        // Missing in API - group by blockchain
        if !missingInAPI.isEmpty {
            message += "⚠️  WALLETS PRESENT ONLY IN UI (\(missingInAPI.count)):\n"
            let groupedByBlockchain = Dictionary(grouping: missingInAPI) { diff -> String in
                let components = diff.walletKey.split(separator: "|")
                return String(components.first ?? "")
            }
            for (blockchain, diffs) in groupedByBlockchain.sorted(by: { $0.key < $1.key }) {
                message += "   📍 \(blockchain) (\(diffs.count) wallet\(diffs.count > 1 ? "s" : "")):\n"
                for diff in diffs.sorted(by: { $0.walletIdentifier < $1.walletIdentifier }) {
                    message += "      • \(diff.walletIdentifier)\n"
                }
            }
            message += "\n"
        }

        // Missing in UI - group by blockchain
        if !missingInUI.isEmpty {
            message += "⚠️  WALLETS PRESENT ONLY IN API (\(missingInUI.count)):\n"
            let groupedByBlockchain = Dictionary(grouping: missingInUI) { diff -> String in
                let components = diff.walletKey.split(separator: "|")
                return String(components.first ?? "")
            }
            for (blockchain, diffs) in groupedByBlockchain.sorted(by: { $0.key < $1.key }) {
                message += "   📍 \(blockchain) (\(diffs.count) wallet\(diffs.count > 1 ? "s" : "")):\n"
                for diff in diffs.sorted(by: { $0.walletIdentifier < $1.walletIdentifier }) {
                    message += "      • \(diff.walletIdentifier)\n"
                }
            }
            message += "\n"
        }

        // Field mismatches - group by blockchain, then by wallet
        if !fieldMismatches.isEmpty {
            message += "❌ FIELD MISMATCHES (\(fieldMismatches.count)):\n\n"

            // First group by blockchain
            let groupedByBlockchain = Dictionary(grouping: fieldMismatches) { diff -> String in
                let components = diff.walletKey.split(separator: "|")
                return String(components.first ?? "")
            }

            for (blockchain, blockchainDiffs) in groupedByBlockchain.sorted(by: { $0.key < $1.key }) {
                message += "   📍 \(blockchain):\n"

                // Then group by wallet key
                let groupedByWallet = Dictionary(grouping: blockchainDiffs) { $0.walletKey }
                for (_, walletDiffs) in groupedByWallet.sorted(by: { $0.key < $1.key }) {
                    let walletId = walletDiffs.first?.walletIdentifier ?? "unknown"
                    message += "      • \(walletId):\n"
                    for diff in walletDiffs.sorted(by: { $0.field ?? "" < $1.field ?? "" }) {
                        message += "         - \(diff.field ?? "unknown"):\n"
                        message += "           UI:  \(diff.uiValue ?? "nil")\n"
                        message += "           API: \(diff.apiValue ?? "nil")\n"
                    }
                }
                message += "\n"
            }
        }

        message += "========================================\n"

        return message
    }
}
