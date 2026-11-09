//
//  YieldModePromoPositionsProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import CombineExt

protocol YieldModePromoPositionsProvider {
    var positionsPublisher: AnyPublisher<[YieldModePromoPosition], Never> { get }
}

struct CommonYieldModePromoPositionsProvider: YieldModePromoPositionsProvider {
    let userWalletModel: any UserWalletModel

    var positionsPublisher: AnyPublisher<[YieldModePromoPosition], Never> {
        AccountWalletModelsAggregator.walletModelsPublisher(from: userWalletModel.accountModelsManager)
            .flatMapLatest { walletModels -> AnyPublisher<[YieldModePromoPosition], Never> in
                let positionPublishers = walletModels.compactMap(Self.positionPublisher(for:))

                guard !positionPublishers.isEmpty else {
                    return Just([]).eraseToAnyPublisher()
                }

                return positionPublishers.combineLatest().eraseToAnyPublisher()
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    private static func positionPublisher(for walletModel: any WalletModel) -> AnyPublisher<YieldModePromoPosition, Never>? {
        guard let yieldModuleManager = walletModel.yieldModuleManager else {
            return nil
        }

        return Publishers.CombineLatest3(
            walletModel.availableBalanceProvider.balanceTypePublisher,
            walletModel.fiatAvailableBalanceProvider.balanceTypePublisher,
            yieldModuleManager.statePublisher
        )
        .compactMap { _ in YieldModePromoPosition(walletModel: walletModel) }
        .removeDuplicates()
        .eraseToAnyPublisher()
    }
}
