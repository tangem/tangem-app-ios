//
//  CryptoAccountModelsSelector.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// The wallet's own accounts that keep crypto tokens. A joint account keeps them too and answers to the same protocol,
/// but it is operated by its members together, so it is asked for on its own — see `JointAccountModelsSelector`.
struct CryptoAccountModelsSelector: AccountModelsSelector {
    func select(from accountModels: [AccountModel]) -> [any CryptoAccountModel] {
        accountModels.flatMap { accountModel -> [any CryptoAccountModel] in
            switch accountModel {
            case .standard(.single(let cryptoAccountModel)): [cryptoAccountModel]
            case .standard(.multiple(let cryptoAccountModels)): cryptoAccountModels
            case .joint, .tangemPay, .polymarket, .collectibles: []
            }
        }
    }

    func selectedPublisher(
        from accountModelsPublisher: AnyPublisher<[AccountModel], Never>
    ) -> AnyPublisher<[any CryptoAccountModel], Never> {
        accountModelsPublisher.map(select(from:)).eraseToAnyPublisher()
    }
}

extension AccountModelsSelector where Self == CryptoAccountModelsSelector {
    static var crypto: Self {
        CryptoAccountModelsSelector()
    }
}
