//
//  WalletModelsManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine

protocol WalletModelsManager {
    var isInitialized: Bool { get }
    var walletModels: [any WalletModel] { get }
    var walletModelsPublisher: AnyPublisher<[any WalletModel], Never> { get }

    func updateAll(silent: Bool, completion: @escaping () -> Void)
}
