//
//  WalletModelsManagerStub.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

@available(iOS, deprecated: 100000.0, message: "Use account-specific 'walletModelsManager' instead and remove this entity ([REDACTED_INFO])")
final class WalletModelsManagerStub: WalletModelsManager {
    private(set) var isInitialized = false

    var walletModels: [any WalletModel] { [] }

    var walletModelsPublisher: AnyPublisher<[any WalletModel], Never> { .just(output: walletModels) }

    func updateAll(silent: Bool) async {}

    func initialize() {
        isInitialized = true
    }
}
