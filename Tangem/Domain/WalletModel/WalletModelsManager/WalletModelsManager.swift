//
//  WalletModelsManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation

protocol WalletModelsManager: Initializable, DisposableEntity, AnyObject {
    var isInitialized: Bool { get }

    var walletModels: [any WalletModel] { get }
    var walletModelsPublisher: AnyPublisher<[any WalletModel], Never> { get }

    func updateAll(silent: Bool) async
}

// MARK: - Await added wallet model

private enum Constants {
    static let walletModelAppearanceTimeout: TimeInterval = 2
}

extension WalletModelsManager {
    func waitForWalletModel(for tokenItem: TokenItem) async -> (any WalletModel)? {
        let walletModelId = WalletModelId(tokenItem: tokenItem)

        if let existing = walletModels.first(where: { $0.id == walletModelId }) {
            return existing
        }

        return try? await walletModelsPublisher
            .compactMap { $0.first { $0.id == walletModelId } }
            .timeout(.seconds(Constants.walletModelAppearanceTimeout), scheduler: DispatchQueue.main)
            .async()
    }
}
