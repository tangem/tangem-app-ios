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
    private var subscription: AnyCancellable?

    init(
        pendingOperationsProvider: any JointAccountPendingOperationsProvider,
        walletModelsManager: WalletModelsManager
    ) {
        self.pendingOperationsProvider = pendingOperationsProvider
        self.walletModelsManager = walletModelsManager

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
                .filter(\.operation.status.isInFlight)
                .map { ($0.operation.id, $0.tokenItem.blockchainNetwork) },
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
