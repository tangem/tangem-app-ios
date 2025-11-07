//
//  LockedWalletModelsManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class LockedWalletModelsManager: WalletModelsManager {
    var isInitialized: Bool { true }
    var walletModels: [any WalletModel] { [] }
    var walletModelsPublisher: AnyPublisher<[any WalletModel], Never> { .just(output: walletModels) }

    func updateAll(silent: Bool, completion: @escaping () -> Void) {
        completion()
    }
}
