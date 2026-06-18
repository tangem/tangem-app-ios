//
//  TokenDeeplinkHandler.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// Self-contained handler for the `tangem://token` deeplink.
///
/// If the token is already in the local portfolio it opens the token details (or express transaction status) screen
/// immediately. Otherwise it tries to sync the user token list with the backend once and re-checks before giving up —
/// this covers the case when the token was added on another device but hasn't reached this device yet.
///
/// - Note: Only the token list is refreshed here. A token that needs key derivation this wallet doesn't have yet won't
///   produce a wallet model and is intentionally left unhandled (no interactive key derivation is performed).
final class TokenDeeplinkHandler {
    @Injected(\.incomingActionManager) private var incomingActionManager: IncomingActionManaging
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    weak var coordinator: MainRoutable?

    private let walletModelLocator: DeeplinkWalletModelLocator

    init(walletModelLocator: DeeplinkWalletModelLocator) {
        self.walletModelLocator = walletModelLocator
    }

    /// Returns `true` when the action is claimed by this handler. A claim is also returned for the asynchronous
    /// sync path so the incoming action manager neither re-dispatches the action to other responders nor re-triggers
    /// it while the sync is still in flight.
    func handle(params: DeeplinkNavigationAction.Params) -> Bool {
        guard
            let coordinator,
            let userWalletModel = walletModelLocator.findUserWalletModel(userWalletModelId: params.userWalletId),
            let tokenId = params.tokenId,
            let networkId = params.networkId
        else {
            incomingActionManager.discardIncomingAction()
            return false
        }

        // Happy path: the token is already present in the local portfolio.
        if let walletModel = walletModelLocator.findWalletModel(in: userWalletModel, tokenId: tokenId, networkId: networkId, derivation: params.derivationPath) {
            guard TokenActionAvailabilityProvider(userWalletInfo: userWalletModel.userWalletInfo, walletModel: walletModel).isTokenInteractionAvailable() else {
                incomingActionManager.discardIncomingAction()
                return false
            }

            return openToken(coordinator: coordinator, params: params, walletModel: walletModel, userWalletModel: userWalletModel)
        }

        // The token is missing from the local portfolio. It may have been added on another device,
        // so try to sync the user token list with the backend and re-check before giving up.
        runTask(in: self) { handler in
            await handler.syncTokensAndOpenTokenIfFound(
                params: params,
                userWalletModel: userWalletModel,
                tokenId: tokenId,
                networkId: networkId
            )
        }

        return true
    }

    /// Opens the token details (or the express transaction status) screen for an already resolved wallet model.
    /// Shared between the synchronous happy path and the post-sync path to keep the navigation logic in one place.
    private func openToken(
        coordinator: MainRoutable,
        params: DeeplinkNavigationAction.Params,
        walletModel: any WalletModel,
        userWalletModel: any UserWalletModel
    ) -> Bool {
        // Trigger the update without awaiting completion
        walletModel.startUpdateTask()

        if case .some(let type) = params.type, type == .onrampStatusUpdate || type == .swapStatusUpdate, let txId = params.transactionId {
            return openExpressTransactionStatus(
                coordinator: coordinator,
                deeplinkType: type,
                transactionId: txId,
                walletModel: walletModel,
                userWalletModel: userWalletModel
            )
        } else {
            coordinator.openDeepLink(.tokenDetails(walletModel: walletModel, userWalletModel: userWalletModel))
            return true
        }
    }

    private func openExpressTransactionStatus(
        coordinator: MainRoutable,
        deeplinkType: IncomingActionConstants.DeeplinkType,
        transactionId: String,
        walletModel: any WalletModel,
        userWalletModel: UserWalletModel
    ) -> Bool {
        let transactionType: PendingTransactionDetails.TransactionType

        switch deeplinkType {
        case .onrampStatusUpdate:
            transactionType = .onramp
        case .swapStatusUpdate:
            transactionType = .swap
        case .incomeTransaction:
            // Transaction status deeplinks are not supported for these types
            return false
        }

        coordinator.openDeepLink(
            .expressTransactionStatus(
                walletModel: walletModel,
                userWalletModel: userWalletModel,
                transactionDetails: .init(type: transactionType, id: transactionId)
            )
        )

        return true
    }

    /// Synchronizes the user token list with the backend, then re-checks the portfolio and opens the token if it appeared.
    private func syncTokensAndOpenTokenIfFound(
        params: DeeplinkNavigationAction.Params,
        userWalletModel: any UserWalletModel,
        tokenId: String,
        networkId: String
    ) async {
        await walletModelLocator.syncUserTokens(
            in: userWalletModel,
            timeout: Constants.tokenListSyncTimeout,
            maxConcurrentSyncs: Constants.maxConcurrentSyncs
        )

        // The token list is refreshed by now, but the matching wallet model is created *reactively*
        // afterwards (token list -> WalletManagersRepository -> WalletModelsManager), so a one-shot
        // lookup right after the sync usually still returns `nil`. Wait (bounded by a timeout) for the
        // wallet model to materialize before giving up.
        let walletModel = await walletModelLocator.waitForWalletModel(
            in: userWalletModel,
            tokenId: tokenId,
            networkId: networkId,
            derivation: params.derivationPath,
            timeout: Constants.walletModelAppearanceTimeout
        )

        await MainActor.run { [weak self] in
            guard
                let self,
                let coordinator,
                !userWalletRepository.isLocked,
                let walletModel,
                TokenActionAvailabilityProvider(userWalletInfo: userWalletModel.userWalletInfo, walletModel: walletModel).isTokenInteractionAvailable()
            else {
                // The action was already claimed (we returned `true`), so `pendingAction` is cleared.
                // Intentionally avoid `discardIncomingAction()` here: a newer pending action may have arrived
                // during the sync and calling it would clobber that unrelated action.
                return
            }

            _ = openToken(coordinator: coordinator, params: params, walletModel: walletModel, userWalletModel: userWalletModel)
        }
    }
}

// MARK: - Constants

private extension TokenDeeplinkHandler {
    enum Constants {
        /// Upper bound for waiting on the user token list sync triggered by a token deeplink miss.
        static let tokenListSyncTimeout: TimeInterval = 10

        /// Upper bound for waiting on the matching wallet model to be created after the token list sync.
        static let walletModelAppearanceTimeout: TimeInterval = 5

        /// Maximum number of per-account token-list syncs running concurrently.
        static let maxConcurrentSyncs = 5
    }
}
