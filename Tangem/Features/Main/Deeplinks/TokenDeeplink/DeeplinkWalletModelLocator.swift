//
//  DeeplinkWalletModelLocator.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

/// Resolves a `UserWalletModel` and a concrete `WalletModel` from token deeplink parameters.
/// Shared by the various deeplink route handlers (token, staking, yield, referral, etc.).
struct DeeplinkWalletModelLocator {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    func findUserWalletModel(userWalletModelId: String?) -> (any UserWalletModel)? {
        guard let userWalletModelId else {
            return userWalletRepository.selectedModel
        }

        return userWalletRepository.models.first { $0.userWalletId.stringValue == userWalletModelId }
    }

    func findWalletModel(
        in userWalletModel: any UserWalletModel,
        tokenId: String,
        networkId: String,
        derivation: String?
    ) -> (any WalletModel)? {
        var walletModels = AccountWalletModelsAggregator.walletModels(from: userWalletModel.accountModelsManager)

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
        timeout: TimeInterval
    ) async -> (any WalletModel)? {
        return try? await AccountWalletModelsAggregator
            .walletModelsPublisher(from: userWalletModel.accountModelsManager)
            .compactMap { [self] _ in
                findWalletModel(in: userWalletModel, tokenId: tokenId, networkId: networkId, derivation: derivation)
            }
            .timeout(.seconds(timeout), scheduler: DispatchQueue.main)
            .async()
    }

    /// Triggers a user token list sync on every crypto account of the wallet and waits for all of them to finish.
    /// Capped by `timeout` because the underlying load can skip its completion when its task gets cancelled,
    /// which would otherwise leave the awaiting task suspended forever.
    func syncUserTokens(
        in userWalletModel: any UserWalletModel,
        timeout: TimeInterval,
        maxConcurrentSyncs: Int
    ) async {
        let cryptoAccounts = userWalletModel.accountModelsManager.cryptoAccountModels

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
    /// stay suspended forever (and keep the enclosing task group alive) when `sync` skips its completion, which happens
    /// when its server load exits early on cancellation.
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
