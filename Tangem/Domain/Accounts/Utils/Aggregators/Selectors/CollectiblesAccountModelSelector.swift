//
//  CollectiblesAccountModelSelector.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt

/// The wallet's collectibles account.
struct CollectiblesAccountModelSelector: AccountModelsSelector {
    let state: CollectiblesAccountState

    func select(from accountModels: [AccountModel]) -> (any CollectiblesAccountModel)? {
        Self.accountModel(from: accountModels).flatMap { state.isMatching($0) ? $0 : nil }
    }

    /// The account outlives the lists it arrives in, so subscribers are only woken when it is a different one.
    func selectedPublisher(
        from accountModelsPublisher: AnyPublisher<[AccountModel], Never>
    ) -> AnyPublisher<(any CollectiblesAccountModel)?, Never> {
        accountModelsPublisher
            .map(Self.accountModel(from:))
            .removeDuplicates { $0?.id == $1?.id }
            .flatMapLatest { [state] accountModel -> AnyPublisher<(any CollectiblesAccountModel)?, Never> in
                guard let accountModel, state == .shown else {
                    return .just(output: accountModel)
                }

                return accountModel
                    .hasAccountPublisher
                    .map { [weak accountModel] hasAccount in hasAccount ? accountModel : nil }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Private logic

private extension CollectiblesAccountModelSelector {
    static func accountModel(from accountModels: [AccountModel]) -> (any CollectiblesAccountModel)? {
        let collectiblesAccountModels = accountModels.compactMap { accountModel -> (any CollectiblesAccountModel)? in
            switch accountModel {
            case .standard, .joint, .tangemPay, .polymarket: nil
            case .collectibles(let collectiblesAccountModel): collectiblesAccountModel
            }
        }

        assert(collectiblesAccountModels.count < 2)
        return collectiblesAccountModels.first
    }
}

// MARK: - CollectiblesAccountState

extension CollectiblesAccountModelSelector {
    enum CollectiblesAccountState {
        case all
        case shown

        func isMatching(_ accountModel: any CollectiblesAccountModel) -> Bool {
            switch self {
            case .all: true
            case .shown: accountModel.hasAccount
            }
        }
    }
}

extension AccountModelsSelector where Self == CollectiblesAccountModelSelector {
    static var collectibles: Self {
        collectibles(.all)
    }

    static func collectibles(_ state: CollectiblesAccountModelSelector.CollectiblesAccountState) -> Self {
        CollectiblesAccountModelSelector(state: state)
    }
}
