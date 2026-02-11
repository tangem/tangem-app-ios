//
//  LockedWalletModelsManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class LockedWalletModelsManager: WalletModelsManager {
    private(set) var isInitialized = false
    var walletModels: [any WalletModel] { [] }
    var walletModelsPublisher: AnyPublisher<[any WalletModel], Never> { .just(output: walletModels) }

    func updateAll(silent: Bool) async {}

    func initialize() {
        isInitialized = true
    }

    func dispose() {}
}
