//
//  JointAccountFinishedOperationsWalletUpdater.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import TangemFoundation

final class JointAccountFinishedOperationsWalletUpdater {
    private let pendingOperationsProvider: any JointAccountPendingOperationsProvider
    private let walletModelsManager: WalletModelsManager
    private let historyDeltaSyncing: JointOperationsHistoryDeltaSyncing
    private var subscription: AnyCancellable?

    init(
        pendingOperationsProvider: any JointAccountPendingOperationsProvider,
        walletModelsManager: WalletModelsManager,
        historyDeltaSyncing: JointOperationsHistoryDeltaSyncing
    ) {
        self.pendingOperationsProvider = pendingOperationsProvider
        self.walletModelsManager = walletModelsManager
        self.historyDeltaSyncing = historyDeltaSyncing

        bind()
    }

    private func bind() {
        subscription = pendingOperationsProvider
            .pendingOperationsPublisher
            .map(Self.inFlightOperationNetworks)
            .pairwise()
            .map { Self.networksOfFinishedOperations(previous: $0, current: $1) }
            .filter(\.isNotEmpty)
            .withWeakCaptureOf(self)
            .sink { updater, networks in
                updater.updateWallets(in: networks)
                updater.syncHistoryDelta()
            }
    }

    func dispose() {
        subscription = nil
    }

    private func syncHistoryDelta() {
        runTask { [historyDeltaSyncing] in
            await historyDeltaSyncing.syncDelta()
        }
    }

    private func updateWallets(in networks: Set<BlockchainNetwork>) {
        for walletModel in walletModelsManager.walletModels where networks.contains(walletModel.tokenItem.blockchainNetwork) {
            walletModel.updateAfterSendingTransaction(silent: true)
        }
    }

    private static func inFlightOperationNetworks(
        _ pendingOperations: [JointAccountPendingOperation]
    ) -> [String: BlockchainNetwork] {
        Dictionary(
            pendingOperations
                .filter(\.status.isInFlight)
                .map { ($0.id, $0.tokenItem.blockchainNetwork) },
            uniquingKeysWith: { _, last in last }
        )
    }

    private static func networksOfFinishedOperations(
        previous: [String: BlockchainNetwork],
        current: [String: BlockchainNetwork]
    ) -> Set<BlockchainNetwork> {
        Set(previous.filter { current[$0.key] == nil }.values)
    }
}
