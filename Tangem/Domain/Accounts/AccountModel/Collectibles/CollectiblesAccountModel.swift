//
//  CollectiblesAccountModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemCollectibles

/// Refines `CollectiblesOnboarder`: the account model owns the vault's state, so it is also what walks that
/// state to `.ready` — the alternative is a second object deciding the same three questions from its own reads.
protocol CollectiblesAccountModel: BaseAccountModel, CollectiblesOnboarder
    where Icon == AccountModel.StandaloneIcon, ID == CollectiblesAccountId {
    var state: CollectiblesState { get }
    var statePublisher: AnyPublisher<CollectiblesState, Never> { get }

    func update(name: String)
    func refreshState() async
}

// MARK: - Default implementations

extension CollectiblesAccountModel {
    var icon: AccountModel.StandaloneIcon {
        .collectibles
    }

    func edit(with editor: (any AccountModelEditor) -> Void) async throws(AccountEditError) -> Self {
        self
    }

    func analyticsParameters(with builder: any AccountsAnalyticsBuilder) -> [Analytics.ParameterKey: String] {
        [:]
    }

    func resolve<R>(using resolver: R) -> R.Result where R: AccountModelResolving {
        resolver.resolve(accountModel: self)
    }
}
