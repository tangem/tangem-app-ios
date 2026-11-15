//
//  UserWalletModel+Collectibles.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import CombineExt
import Foundation
import TangemCollectibles

extension UserWalletModel {
    var isCollectiblesEligible: Bool {
        guard !isUserWalletLocked, config.hasFeature(.multiCurrency), config.hasFeature(.hdWallets) else {
            return false
        }

        return (try? keysRepository.masterKey(curve: CollectiblesAccountKeyPath.curve(for: config.derivationStyle))) != nil
    }

    func collectiblesAccountModel() -> (any CollectiblesAccountModel)? {
        AccountModelsAggregator(.collectibles).model(from: accountModelsManager)
    }

    var collectiblesSyncRequiredPublisher: AnyPublisher<Bool, Never> {
        AccountModelsAggregator(.collectibles)
            .modelPublisher(from: accountModelsManager)
            .flatMapLatest { accountModel -> AnyPublisher<Bool, Never> in
                accountModel?.isSyncRequiredPublisher ?? .just(output: false)
            }
            .eraseToAnyPublisher()
    }
}
