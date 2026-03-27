//
//  TangemPayAccountModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemPay
import TangemLocalization

protocol TangemPayAccountModel: BaseAccountModel {
    var standaloneIcon: AccountModel.StandaloneIcon { get }

    var state: TangemPayLocalState? { get }
    var statePublisher: AnyPublisher<TangemPayLocalState, Never> { get }

    var customerId: String? { get }

    func refreshState() async
    func syncTokens(
        authorizingInteractor: TangemPayAuthorizing,
        pendingDerivations: [PendingDerivation],
        completion: @escaping () -> Void
    )
}

// MARK: - Default implementations

extension TangemPayAccountModel {
    func edit(with editor: (any AccountModelEditor) -> Void) async throws(AccountEditError) -> Self {
        self
    }

    func analyticsParameters(with builder: any AccountsAnalyticsBuilder) -> [Analytics.ParameterKey: String] {
        [:]
    }

    func resolve<R>(using resolver: R) -> R.Result where R: AccountModelResolving {
        resolver.resolve(accountModel: self)
    }

    var standaloneIcon: AccountModel.StandaloneIcon {
        .tangemPay
    }

    var icon: AccountModel.Icon {
        .standalone(standaloneIcon)
    }

    var name: String {
        Localization.tangempayPaymentAccount
    }

    var didChangePublisher: AnyPublisher<Void, Never> {
        .empty
    }
}
