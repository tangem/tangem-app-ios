//
//  SilentPushTesterViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import UIKit
import TangemFoundation

/// Debug-only screen that fabricates a transactional push payload and feeds it through the two
/// real entry points so both flows can be exercised without APNs:
/// - **Send (silent):** routes the payload through `AppDelegate.didReceiveRemoteNotification`,
///   passing the `.active` gate and ending in `TransactionPushPortfolioUpdater` (refresh, no navigation).
/// - **Send as tap:** builds the same `tangem://token` deeplink the tap flow produces and hands it to
///   `IncomingActionHandler` (navigation).
final class SilentPushTesterViewModel: ObservableObject {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.incomingActionHandler) private var incomingActionHandler: IncomingActionHandler

    @Published var userWalletId: String = ""
    @Published var networkId: String = ""
    @Published var tokenId: String = ""
    @Published var derivationPath: String = ""
    @Published var selectedType: IncomingActionConstants.DeeplinkType = .incomeTransaction
    @Published var scenario: Scenario = .hit
    @Published var lastResultMessage: String = ""

    let types: [IncomingActionConstants.DeeplinkType] = [.incomeTransaction, .onrampStatusUpdate, .swapStatusUpdate]

    enum Scenario: String, CaseIterable, Identifiable {
        case hit = "Hit (token in list)"
        case miss = "Miss (unknown token)"

        var id: String { rawValue }
    }

    /// In the `miss` scenario we mangle the token id so `findWalletModel` misses on purpose,
    /// forcing the `syncUserTokens` + `waitForWalletModel` branch in `TransactionPushPortfolioUpdater`.
    private var effectiveTokenId: String {
        switch scenario {
        case .hit:
            return tokenId
        case .miss:
            return tokenId + "_nonexistent_" + String(UUID().uuidString.prefix(8))
        }
    }

    func fillFromCurrentWallet() {
        guard let userWalletModel = userWalletRepository.selectedModel else {
            lastResultMessage = "No selected wallet to fill from."
            return
        }

        userWalletId = userWalletModel.userWalletId.stringValue

        let walletModels = AccountWalletModelsAggregator.walletModels(from: userWalletModel.accountModelsManager)

        guard let walletModel = walletModels.first(where: { !$0.isCustom }) ?? walletModels.first else {
            lastResultMessage = "Selected wallet has no tokens to fill from."
            return
        }

        networkId = walletModel.tokenItem.blockchain.networkId
        tokenId = walletModel.tokenItem.id ?? ""
        derivationPath = walletModel.tokenItem.blockchainNetwork.derivationPath?.rawPath ?? ""
        lastResultMessage = "Filled from \(walletModel.tokenItem.name)."
    }

    /// Variant B — routes through the real `AppDelegate` entry point (including the `.active` gate).
    func sendAsSilentPush() {
        let application = UIApplication.shared
        application.delegate?.application?(
            application,
            didReceiveRemoteNotification: makeUserInfo(),
            fetchCompletionHandler: { _ in }
        )
        lastResultMessage = "Sent silent push (state: \(applicationStateDescription(application.applicationState)))."
    }

    /// Builds the same deeplink the tap flow produces and hands it to the incoming-action handler.
    func sendAsTap() {
        let helper = TransactionPushActionURLHelper(
            type: selectedType.rawValue,
            networkId: networkId,
            tokenId: effectiveTokenId,
            userWalletId: userWalletId,
            derivationPath: derivationPath.nilIfEmpty
        )

        let url = helper.buildURL(scheme: .withoutRedirectUniversalLink)
        let handled = incomingActionHandler.handleIncomingURL(url)
        lastResultMessage = handled ? "Tap deeplink handled: \(url.absoluteString)" : "Tap deeplink NOT handled: \(url.absoluteString)"
    }

    /// Mirrors the backend payload shape that `TransactionPushPayload` expects, including sending the
    /// literal string `"null"` for empty optionals (the backend does the same).
    private func makeUserInfo() -> [AnyHashable: Any] {
        let params = IncomingActionConstants.DeeplinkParams.self

        return [
            "aps": [
                "content-available": 1,
            ],
            params.type: selectedType.rawValue,
            params.networkId: networkId,
            params.tokenId: effectiveTokenId,
            params.userWalletId: userWalletId,
            params.derivationPath: derivationPath.nilIfEmpty ?? "null",
        ]
    }

    private func applicationStateDescription(_ state: UIApplication.State) -> String {
        switch state {
        case .active: return "active"
        case .inactive: return "inactive"
        case .background: return "background"
        @unknown default: return "unknown"
        }
    }
}
