//
//  WalletModelsManagerMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

struct WalletModelsManagerMock: WalletModelsManager {
    var walletModels: [WalletModel] { [] }
    var walletModelsPublisher: AnyPublisher<[WalletModel], Never> { .just(output: []) }
    var signatureCountValidator: BlockchainSdk.SignatureCountValidator? { nil }

    func updateAll(silent: Bool, completion: @escaping () -> Void) {}
}
