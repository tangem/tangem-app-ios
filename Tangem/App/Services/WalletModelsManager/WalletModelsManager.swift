//
//  WalletModelsManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Combine

protocol WalletModelsManager {
    var walletModels: [WalletModel] { get }
    var walletModelsPublisher: AnyPublisher<[WalletModel], Never> { get }
    var signatureCountValidator: SignatureCountValidator? { get }

    func updateAll(silent: Bool, completion: @escaping () -> Void)
}
