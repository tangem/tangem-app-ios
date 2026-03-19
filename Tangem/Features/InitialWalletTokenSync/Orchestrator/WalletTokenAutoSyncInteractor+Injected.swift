//
//  WalletTokenAutoSyncInteractor+Injected.swift
//  Tangem
//
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - Shared Queue

private let sharedMoralisQueue = MoralisRateLimitedRequestQueue()
private let sharedSyncStateActor = WalletTokenAutoSyncStateActor()

// MARK: - InjectionKey

private struct WalletTokenAutoSyncInteractorKey: InjectionKey {
    static var currentValue: WalletTokenAutoSyncInteractor = CommonWalletTokenAutoSyncOrchestrator(
        addressResolver: WalletAddressResolver(),
        tokenBalanceClient: RateLimitedMoralisTokenBalanceClient(
            client: CommonMoralisTokenBalanceClient(provider: nil),
            queue: sharedMoralisQueue
        ),
        tangemApiService: InjectedValues[\.tangemApiService],
        syncStateActor: sharedSyncStateActor,
        progressService: InjectedValues[\.walletTokenSyncProgressService]
    )
}

// MARK: - InjectedValues

extension InjectedValues {
    var walletTokenAutoSyncInteractor: WalletTokenAutoSyncInteractor {
        get { Self[WalletTokenAutoSyncInteractorKey.self] }
        set { Self[WalletTokenAutoSyncInteractorKey.self] = newValue }
    }
}
