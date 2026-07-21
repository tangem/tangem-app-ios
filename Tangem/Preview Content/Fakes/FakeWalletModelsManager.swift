//
//  FakeWalletModelsManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk
import TangemFoundation

class FakeWalletModelsManager: WalletModelsManager {
    private(set) var isInitialized = false

    var walletModels: [any WalletModel] {
        walletModelsSubject.value
    }

    var walletModelsPublisher: AnyPublisher<[any WalletModel], Never> {
        walletModelsSubject
            .delay(for: isDelayed ? 5.0 : 0.0, scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    private let walletModelsSubject: CurrentValueSubject<[any WalletModel], Never>
    private let isDelayed: Bool
    private var updateAllSubscription: AnyCancellable?

    init(
        walletManagers: [FakeWalletManager],
        isDelayed: Bool
    ) {
        walletModelsSubject = .init(walletManagers.flatMap { $0.walletModels })
        self.isDelayed = isDelayed
    }

    func updateAll(silent: Bool) async {
        // Single token shared across the batch of all wallet models, so all updates belong to the same cycle
        let updateToken = UUID()

        await TaskGroup.executeKeepingOrder(items: walletModels) {
            await $0.update(silent: silent, options: .balances, updateToken: updateToken)
        }
    }

    func initialize() {
        isInitialized = true
    }

    func dispose() {
        walletModelsSubject.send([])
    }
}
