//
//  LockedWalletModelsManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import protocol BlockchainSdk.SignatureCountValidator

struct LockedWalletModelsManager: WalletModelsManager {
    var walletModels: [WalletModel] { [] }
    var walletModelsPublisher: AnyPublisher<[WalletModel], Never> { .just(output: []) }
    var signatureCountValidator: SignatureCountValidator? { nil }

    func updateAll(silent: Bool, completion: @escaping () -> Void) {
        completion()
    }
}
