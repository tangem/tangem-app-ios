//
//  TransactionPushPortfolioUpdater.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

/// Silent-push subscriber that refreshes portfolio data for transactional pushes.
///
/// When the user *taps* a transactional push, `CommonIncomingActionManager` builds a `tangem://token`
/// deeplink and `TokenDeeplinkHandler` both navigates and refreshes balances. A *silent* push arriving
/// while the app is active has no user intent to navigate, so this handler only mirrors the refresh part:
/// it locates the wallet model from the payload and triggers an update. If the token isn't in the local
/// portfolio yet (e.g. added on another device), it syncs the token list first — the same recovery the
/// deeplink handler performs — and updates once the wallet model materializes.
///
/// Non-transactional payloads are ignored: other `SilentPushNotificationHandling` subscribers handle those.
final class TransactionPushPortfolioUpdater {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.silentPushNotificationsPublisher) private var silentPushNotificationsPublisher: SilentPushNotificationsPublishing

    private let walletModelLocator = DeeplinkWalletModelLocator()
    private var cancellable: AnyCancellable?

    init() {
        bind()
    }

    private func bind() {
        cancellable = silentPushNotificationsPublisher.silentPushPublisher
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .sink { updater, userInfo in
                updater.handle(userInfo)
            }
    }
}

// MARK: - SilentPushNotificationHandling

extension TransactionPushPortfolioUpdater: SilentPushNotificationHandling {
    func handle(_ userInfo: SilentPushUserInfo) {
        guard
            let payload = TransactionPushPayload(userInfo: userInfo.raw),
            let userWalletModel = walletModelLocator.findUserWalletModel(userWalletModelId: payload.userWalletId)
        else {
            return
        }

        // Happy path: the token is already present in the local portfolio — refresh it right away.
        if let walletModel = walletModelLocator.findWalletModel(
            in: userWalletModel,
            tokenId: payload.tokenId,
            networkId: payload.networkId,
            derivation: payload.derivationPath
        ) {
            guard !userWalletRepository.isLocked else {
                return
            }

            walletModel.startUpdateTask()
            return
        }
        // The token is missing locally; sync the token list and refresh once it appears.
        runTask(in: self) { updater in
            await updater.syncTokensAndUpdateIfFound(payload: payload, userWalletModel: userWalletModel)
        }
    }
}

// MARK: - Private

private extension TransactionPushPortfolioUpdater {
    func syncTokensAndUpdateIfFound(payload: TransactionPushPayload, userWalletModel: any UserWalletModel) async {
        await walletModelLocator.syncUserTokens(
            in: userWalletModel,
            timeout: Constants.tokenListSyncTimeout,
            maxConcurrentSyncs: Constants.maxConcurrentSyncs
        )

        let walletModel = await walletModelLocator.waitForWalletModel(
            in: userWalletModel,
            tokenId: payload.tokenId,
            networkId: payload.networkId,
            derivation: payload.derivationPath,
            timeout: Constants.walletModelAppearanceTimeout
        )

        await MainActor.run { [weak self] in
            guard
                let self,
                !userWalletRepository.isLocked,
                let walletModel
            else {
                return
            }

            walletModel.startUpdateTask()
        }
    }
}

// MARK: - Constants

private extension TransactionPushPortfolioUpdater {
    enum Constants {
        /// Upper bound for waiting on the user token list sync triggered by a silent transactional push miss.
        static let tokenListSyncTimeout: TimeInterval = 10

        /// Upper bound for waiting on the matching wallet model to be created after the token list sync.
        static let walletModelAppearanceTimeout: TimeInterval = 5

        /// Maximum number of per-account token-list syncs running concurrently.
        static let maxConcurrentSyncs = 5
    }
}
