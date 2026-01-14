//
//  MockWalletModelsManager.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
@testable import Tangem

final class WalletModelsManagerTestsMock: WalletModelsManager {
    var isInitialized: Bool = true
    var walletModels: [any WalletModel] = []

    private let walletModelsSubject = CurrentValueSubject<[any WalletModel], Never>([])

    var walletModelsPublisher: AnyPublisher<[any WalletModel], Never> {
        walletModelsSubject.eraseToAnyPublisher()
    }

    func sendUpdate() {
        walletModelsSubject.send(walletModels)
    }

    func initialize() {}

    func updateAll(silent: Bool) async {}
}
