//
//  JointAccountCryptoModelsAggregator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// Picks the joint accounts out of the account list. A wallet may take part in several, and the ones still being put
/// together are asked for separately — they hold no tokens and are shown by a plate of their own.
enum JointAccountCryptoModelsAggregator {
    static func jointAccountModels(from accountModels: [AccountModel]) -> [any JointAccountModel] {
        accountModels.flatMap { accountModel -> [any JointAccountModel] in
            switch accountModel {
            case .joint(let jointAccountModels): jointAccountModels
            case .standard, .tangemPay, .polymarket, .collectibles: []
            }
        }
    }

    static func pendingJointAccountModels(from accountModels: [AccountModel]) -> [any JointAccountModel] {
        // Spelled out rather than reached for by key path, which crashes the compiler on an existential like this one
        jointAccountModels(from: accountModels).filter { $0.isAwaitingActivation }
    }

    static func pendingJointAccountModels(from accountModelsManager: any AccountModelsManager) -> [any JointAccountModel] {
        pendingJointAccountModels(from: accountModelsManager.accountModels)
    }

    static func pendingJointAccountModelsPublisher(
        from accountModelsManager: any AccountModelsManager
    ) -> AnyPublisher<[any JointAccountModel], Never> {
        accountModelsManager
            .accountModelsPublisher
            .map(pendingJointAccountModels(from:))
            .eraseToAnyPublisher()
    }
}
