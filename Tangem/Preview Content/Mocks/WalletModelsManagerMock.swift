//
//  WalletModelsManagerMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class WalletModelsManagerMock: WalletModelsManager {
    private(set) var isInitialized = false
    var walletModels: [any WalletModel] { [CommonWalletModel.mockETH] }
    var walletModelsPublisher: AnyPublisher<[any WalletModel], Never> { .just(output: walletModels) }

    func updateAll(silent: Bool, completion: @escaping () -> Void) {
        completion()
    }

    func initialize() {
        isInitialized = true
    }
}
