//
//  PolymarketLaunchDepositsReconciler.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemPolymarket

protocol PolymarketLaunchDepositsReconciling {
    @discardableResult
    func reconcileOncePerLaunch(ownerAddress: String) -> Task<Void, Never>?
}

final class PolymarketLaunchDepositsReconciler {
    typealias RegionCheck = () async -> Bool
    typealias Reconcile = (_ depositWalletAddress: String) async throws -> Void

    private let walletKey: String
    private let ledger: PolymarketLaunchLedger
    private let isRegionBlocked: RegionCheck
    private let reconcile: Reconcile

    init(
        walletKey: String,
        ledger: PolymarketLaunchLedger = .shared,
        isRegionBlocked: @escaping RegionCheck,
        reconcile: @escaping Reconcile
    ) {
        self.walletKey = walletKey
        self.ledger = ledger
        self.isRegionBlocked = isRegionBlocked
        self.reconcile = reconcile
    }
}

// MARK: - PolymarketLaunchDepositsReconciling protocol conformance

extension PolymarketLaunchDepositsReconciler: PolymarketLaunchDepositsReconciling {
    @discardableResult
    func reconcileOncePerLaunch(ownerAddress: String) -> Task<Void, Never>? {
        guard ledger.claim(walletKey) else { return nil }

        let isRegionBlocked = isRegionBlocked
        let reconcile = reconcile

        return Task {
            guard await !isRegionBlocked() else { return }

            do {
                try await reconcile(PolymarketDepositWalletDeriver.derive(ownerAddress: ownerAddress))
            } catch {
                guard !error.isCancellationError else { return }

                PolymarketActivityFailure.log(error, while: "ask for a deposits scan on launch")
            }
        }
    }
}

// MARK: - Factory

extension PolymarketLaunchDepositsReconciler {
    static func make(userWalletId: UserWalletId) -> PolymarketLaunchDepositsReconciler {
        let walletId = userWalletId.stringValue

        return PolymarketLaunchDepositsReconciler(
            walletKey: walletId,
            isRegionBlocked: {
                let geoblock = try? await PolymarketOnboardingServicesFactory.makeDefault().makeGeoblockService().geoblock()
                return geoblock?.isBlocked ?? false
            },
            reconcile: { depositWalletAddress in
                try await PolymarketAPIProviderFactory()
                    .makeProvider(walletId: walletId)
                    .reconcileDeposits(depositWalletAddress: depositWalletAddress)
            }
        )
    }
}

// MARK: - Launch ledger

final class PolymarketLaunchLedger {
    static let shared = PolymarketLaunchLedger()

    private let claimedKeys = OSAllocatedUnfairLock<Set<String>>(initialState: [])

    func claim(_ key: String) -> Bool {
        claimedKeys.withLock { $0.insert(key).inserted }
    }
}
