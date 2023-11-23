//
//  CommonExpressDestinationService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct CommonExpressDestinationService {
    private let walletModelsManager: WalletModelsManager

    init(walletModelsManager: WalletModelsManager) {
        self.walletModelsManager = walletModelsManager
    }
}

// MARK: - ExpressDestinationService

extension CommonExpressDestinationService: ExpressDestinationService {
    func getDestination(source: WalletModel) async throws -> WalletModel {
        // [REDACTED_TODO_COMMENT]

        if source.isMainToken {
            if let wallet = walletModelsManager.walletModels.first(where: {
                $0.blockchainNetwork == source.blockchainNetwork && $0.id != source.id
            }) {
                return wallet
            }
        }

        if source.isToken {
            if let wallet = walletModelsManager.walletModels.first(where: {
                $0.blockchainNetwork == source.blockchainNetwork && $0.isMainToken
            }) {
                return wallet
            }
        }

        throw CommonError.noData
    }
}
