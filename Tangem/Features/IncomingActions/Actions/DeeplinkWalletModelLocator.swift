//
//  DeeplinkWalletModelLocator.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

/// Finds the wallet and the token a deeplink names. Shared by every destination that names one.
struct DeeplinkWalletModelLocator {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    /// A token of a wallet, which is what most links point at.
    struct Target {
        let walletModel: any WalletModel
        let userWalletModel: any UserWalletModel
    }

    /// The wallet the link names, or the selected one when it names none.
    func findUserWalletModel(userWalletModelId: String?) -> (any UserWalletModel)? {
        guard let userWalletModelId else {
            return userWalletRepository.selectedModel
        }

        return userWalletRepository.models.first { $0.userWalletId.stringValue == userWalletModelId }
    }

    /// The same, unless the wallet can't do what the link asks of it.
    func findUserWalletModel(userWalletModelId: String?, requiring feature: UserWalletFeature) -> (any UserWalletModel)? {
        guard let userWalletModel = findUserWalletModel(userWalletModelId: userWalletModelId),
              userWalletModel.config.hasFeature(feature)
        else {
            return nil
        }

        return userWalletModel
    }

    func findTarget(
        userWalletId: String?,
        tokenId: String,
        networkId: String,
        derivationPath: String?,
        requiring feature: UserWalletFeature? = nil
    ) -> Target? {
        let userWalletModel = feature
            .map { findUserWalletModel(userWalletModelId: userWalletId, requiring: $0) }
            ?? findUserWalletModel(userWalletModelId: userWalletId)

        guard
            let userWalletModel,
            let walletModel = findWalletModel(in: userWalletModel, tokenId: tokenId, networkId: networkId, derivation: derivationPath, accountId: nil)
        else {
            return nil
        }

        return Target(walletModel: walletModel, userWalletModel: userWalletModel)
    }

    /// The token a link names, syncing the user token list once when it isn't in the portfolio yet: it may have
    /// been added on another device and not reached this one.
    func findTarget(
        userWalletId: String?,
        tokenId: String,
        networkId: String,
        derivationPath: String?,
        accountId: String?,
        syncingTokenList: Bool
    ) async -> Target? {
        guard let userWalletModel = findUserWalletModel(userWalletModelId: userWalletId) else {
            return nil
        }

        if let walletModel = findWalletModel(in: userWalletModel, tokenId: tokenId, networkId: networkId, derivation: derivationPath, accountId: accountId) {
            return Target(walletModel: walletModel, userWalletModel: userWalletModel)
        }

        guard syncingTokenList else {
            return nil
        }

        if let accountId, !hasAccount(withId: accountId, in: userWalletModel) {
            await userWalletModel.accountModelsManager.reloadAccountsFromRemote()
        }

        await syncUserTokens(
            in: userWalletModel,
            timeout: Constants.tokenListSyncTimeout,
            maxConcurrentSyncs: Constants.maxConcurrentSyncs
        )

        // The token list is refreshed by now, but the matching wallet model is created *reactively*
        // afterwards (token list -> WalletManagersRepository -> WalletModelsManager), so a one-shot
        // lookup right after the sync usually still returns `nil`. Wait (bounded by a timeout) for the
        // wallet model to materialize before giving up.
        let walletModel = await waitForWalletModel(
            in: userWalletModel,
            tokenId: tokenId,
            networkId: networkId,
            derivation: derivationPath,
            accountId: accountId,
            timeout: Constants.walletModelAppearanceTimeout
        )

        return walletModel.map { Target(walletModel: $0, userWalletModel: userWalletModel) }
    }

    func findWalletModel(
        in userWalletModel: any UserWalletModel,
        tokenId: String,
        networkId: String,
        derivation: String?,
        accountId: String?
    ) -> (any WalletModel)? {
        var walletModels = AccountWalletModelsAggregator.walletModels(from: userWalletModel.accountModelsManager)

        if let accountId = accountId?.nilIfEmpty {
            let accountWalletModels = walletModels.filter { Self.accountIdentifier(of: $0.account) == accountId }

            if let walletModel = findWalletModel(in: accountWalletModels, tokenId: tokenId, networkId: networkId, derivation: derivation) {
                return walletModel
            }

            guard derivation != nil else {
                return nil
            }

            return findWalletModel(in: accountWalletModels, tokenId: tokenId, networkId: networkId, derivation: nil)
        }

        // If derivation is missing, prefer main account's wallet model - this is why we sort them here
        walletModels.sort { first, second in
            let isFirstMainAccount = first.account?.isMainAccount ?? false
            let isSecondMainAccount = second.account?.isMainAccount ?? false
            return isFirstMainAccount && !isSecondMainAccount
        }

        return findWalletModel(
            in: walletModels,
            tokenId: tokenId,
            networkId: networkId,
            derivation: derivation
        )
    }

    private func findWalletModel(
        in walletModels: [any WalletModel],
        tokenId: String,
        networkId: String,
        derivation: String?
    ) -> (any WalletModel)? {
        // Strict match if derivation is provided
        if let derivation = derivation?.nilIfEmpty {
            return walletModels.first { isMatch($0, tokenId: tokenId, networkId: networkId, derivationPath: derivation) }
        }

        // Loose match with fallback if derivation is not provided
        let matchingModels = walletModels.filter { isMatch($0, tokenId: tokenId, networkId: networkId, derivationPath: nil) }
        return matchingModels.first(where: { !$0.isCustom }) ?? matchingModels.first
    }

    private func isMatch(_ model: any WalletModel, tokenId: String, networkId: String, derivationPath: String?) -> Bool {
        let idMatch = model.tokenItem.id == tokenId
        let networkMatch = model.tokenItem.blockchain.networkId == networkId
        let derivationPathMatch = derivationPath.map { $0 == model.tokenItem.blockchainNetwork.derivationPath?.rawPath } ?? true
        return idMatch && networkMatch && derivationPathMatch
    }
}

// MARK: - Accounts

extension DeeplinkWalletModelLocator {
    static func accountIdentifier(of account: (any CryptoAccountModel)?) -> String? {
        account?.id.rawValue.hexString.lowercased()
    }

    func hasAccount(withId accountId: String, in userWalletModel: any UserWalletModel) -> Bool {
        AccountModelsAggregator(.crypto, .joint)
            .models(from: userWalletModel.accountModelsManager)
            .contains { (account: any CryptoAccountModel) in Self.accountIdentifier(of: account) == accountId }
    }

    func findJointAccount(withId accountId: String, in userWalletModel: any UserWalletModel) async -> (any JointAccountModel)? {
        if let account = await waitForAccount(withId: accountId, in: userWalletModel) {
            return account as? any JointAccountModel
        }

        await userWalletModel.accountModelsManager.reloadAccountsFromRemote()

        return await waitForAccount(withId: accountId, in: userWalletModel) as? any JointAccountModel
    }

    private func waitForAccount(withId accountId: String, in userWalletModel: any UserWalletModel) async -> (any CryptoAccountModel)? {
        try? await AccountModelsAggregator(.crypto, .joint)
            .modelsPublisher(from: userWalletModel.accountModelsManager)
            .compactMap { (accounts: [any CryptoAccountModel]) in
                accounts.first { Self.accountIdentifier(of: $0) == accountId }
            }
            .timeout(.seconds(Constants.accountAppearanceTimeout), scheduler: DispatchQueue.main)
            .async()
    }
}

// MARK: - Token list sync

extension DeeplinkWalletModelLocator {
    /// Waits for the wallet model matching the given parameters to appear in the portfolio after a token list sync.
    /// Returns `nil` if it does not materialize within `timeout` (e.g. the token isn't on the backend list either,
    /// or it needs key derivation this wallet doesn't have).
    func waitForWalletModel(
        in userWalletModel: any UserWalletModel,
        tokenId: String,
        networkId: String,
        derivation: String?,
        accountId: String?,
        timeout: TimeInterval
    ) async -> (any WalletModel)? {
        return try? await AccountWalletModelsAggregator
            .walletModelsPublisher(from: userWalletModel.accountModelsManager)
            .compactMap { [self] _ in
                findWalletModel(in: userWalletModel, tokenId: tokenId, networkId: networkId, derivation: derivation, accountId: accountId)
            }
            .timeout(.seconds(timeout), scheduler: DispatchQueue.main)
            .async()
    }

    /// Triggers a user token list sync on every crypto account of the wallet and waits for all of them to finish.
    /// Capped by `timeout` because a sync finishes only after a full wallet models update — network requests with
    /// a timeout of their own and node failover — which is too long to keep the deeplink navigation waiting.
    func syncUserTokens(
        in userWalletModel: any UserWalletModel,
        timeout: TimeInterval,
        maxConcurrentSyncs: Int
    ) async {
        let cryptoAccounts = AccountModelsAggregator(.crypto, .joint).models(from: userWalletModel.accountModelsManager)

        guard cryptoAccounts.isNotEmpty else {
            return
        }

        // The timeout failure (and cancellation) is intentionally swallowed: in either case we just stop
        // waiting and let the caller re-check the portfolio.
        try? await Task.run(withTimeout: .seconds(timeout)) {
            await withTaskGroup(of: Void.self) { group in
                // Bounded concurrency via a sliding window: keep at most `maxConcurrentSyncs` syncs in flight
                // so a wallet with many crypto accounts can't flood the network (and the cooperative thread
                // pool) with simultaneous requests. Mirrors `CommonWalletModelsManager.updateAllInternal`.
                let count = cryptoAccounts.count
                let concurrencyLimit = max(1, maxConcurrentSyncs)

                for index in 0 ..< count {
                    if index >= concurrencyLimit {
                        await group.next()
                    }

                    _ = group.addTaskUnlessCancelled {
                        await sync(userTokensManager: cryptoAccounts[index].userTokensManager)
                    }
                }

                await group.waitForAll()
            }
        }
    }

    /// Bridges the completion-handler `sync` into async while staying cancellation-safe. The continuation is resumed
    /// exactly once — from either the sync completion or the cancellation handler — so a cancelled child task can't
    /// keep the enclosing task group alive waiting for a callback that `sync`, being unaware of task cancellation,
    /// delivers on its own schedule.
    private func sync(userTokensManager: UserTokensManager) async {
        let continuationCancellableWrapper = ThreadSafeCancellableWrapper()

        await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                let resumeOnce = ResumeOnceContinuation(continuation)

                // Lets `onCancel` reach the continuation even if it fires before/while this closure runs;
                // `set` resumes immediately when cancellation already happened (race between `onCancel` and `set`).
                continuationCancellableWrapper.set(AnyCancellable { resumeOnce.resume() })

                guard !Task.isCancelled else {
                    resumeOnce.resume()
                    return
                }

                userTokensManager.sync {
                    resumeOnce.resume()
                }
            }
        } onCancel: {
            continuationCancellableWrapper.cancel()
        }
    }
}

// MARK: - ResumeOnceContinuation

private extension DeeplinkWalletModelLocator {
    /// Resumes the wrapped continuation exactly once, from whichever of the sync completion or the cancellation
    /// handler fires first. Internally synchronized, hence `@unchecked Sendable`.
    final class ResumeOnceContinuation: @unchecked Sendable {
        private let continuation: CheckedContinuation<Void, Never>
        private let isResumed = OSAllocatedUnfairLock(initialState: false)

        init(_ continuation: CheckedContinuation<Void, Never>) {
            self.continuation = continuation
        }

        func resume() {
            let shouldResume = isResumed.withLock { resumed in
                guard !resumed else { return false }
                resumed = true
                return true
            }

            // Resuming is performed outside the critical section to avoid potential deadlocks.
            if shouldResume {
                continuation.resume()
            }
        }
    }
}

// MARK: - Constants

private extension DeeplinkWalletModelLocator {
    enum Constants {
        /// Upper bound for waiting on the user token list sync triggered by a deeplink miss.
        static let tokenListSyncTimeout: TimeInterval = 10

        /// Upper bound for waiting on the matching wallet model to be created after the token list sync.
        static let walletModelAppearanceTimeout: TimeInterval = 5

        static let accountAppearanceTimeout: TimeInterval = 3

        /// Maximum number of per-account token-list syncs running concurrently.
        static let maxConcurrentSyncs = 5
    }
}
