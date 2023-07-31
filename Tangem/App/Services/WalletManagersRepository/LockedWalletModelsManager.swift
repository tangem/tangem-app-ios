//
//  LockedWalletModelsManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

struct LockedWalletModelsManager: WalletModelsManager {
    var walletModels: [WalletModel] { [] }
    var walletModelsPublisher: AnyPublisher<[WalletModel], Never> { .just(output: []) }

    func updateAll(silent: Bool, completion: @escaping () -> Void) {
        completion()
    }
}
