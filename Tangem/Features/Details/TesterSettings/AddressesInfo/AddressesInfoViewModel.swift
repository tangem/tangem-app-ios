//
//  AddressesInfoViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import TangemFoundation
import UIKit
import BlockchainSdk

/// View model that composes the same derivation/token information
/// we include in support emails and exposes it as JSON.
final class AddressesInfoViewModel: ObservableObject {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    /// JSON representation of the derivations/tokens info
    @Published var text: String = ""

    init() {
        text = generateJSONFormat()
    }

    private func generateJSONFormat() -> String {
        var wallets: [WalletInfoJSON] = []

        for userWallet in userWalletRepository.models {
            let walletModels = AccountsFeatureAwareWalletModelsResolver.walletModels(for: userWallet)

            for walletModel in walletModels {
                let derivationPath = walletModel.publicKey.derivationPath

                let addresses = walletModel.addresses.map { $0.value }

                let walletInfo = WalletInfoJSON(
                    addresses: addresses,
                    blockchain: walletModel.tokenItem.networkName,
                    derivationPath: derivationPath?.rawPath ?? "",
                    token: walletModel.tokenItem.name
                )

                wallets.append(walletInfo)
            }
        }

        // Sort wallets for consistent comparison
        wallets.sort { lhs, rhs in
            let lhsKey = "\(lhs.blockchain)-\(lhs.derivationPath)-\(lhs.token ?? "")"
            let rhsKey = "\(rhs.blockchain)-\(rhs.derivationPath)-\(rhs.token ?? "")"
            return lhsKey < rhsKey
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        do {
            let jsonData = try encoder.encode(wallets)
            return String(data: jsonData, encoding: .utf8) ?? "Failed to encode JSON"
        } catch {
            return "Error encoding JSON: \(error.localizedDescription)"
        }
    }

    func copyToClipboard() {
        UIPasteboard.general.string = text
    }
}

// MARK: - JSON Models

private struct WalletInfoJSON: Codable {
    let addresses: [String]
    let blockchain: String
    let derivationPath: String
    let token: String?

    enum CodingKeys: String, CodingKey {
        case addresses
        case blockchain
        case derivationPath
        case token
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(addresses, forKey: .addresses)
        try container.encode(blockchain, forKey: .blockchain)
        try container.encode(derivationPath, forKey: .derivationPath)

        if let token = token, !token.isEmpty {
            try container.encode(token, forKey: .token)
        }
    }
}
