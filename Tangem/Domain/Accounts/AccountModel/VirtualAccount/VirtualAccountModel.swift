//
//  VirtualAccountModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemPay
import TangemLocalization

protocol VirtualAccountModel: BaseAccountModel {
    var state: VirtualAccountLocalState? { get }
    var statePublisher: AnyPublisher<VirtualAccountLocalState, Never> { get }

    var customerId: String? { get }

    func refreshState() async
    func syncTokens(
        authorizingInteractor: PaymentAccountAuthorizing,
        completion: @escaping () -> Void
    )
}

// MARK: - Default implementations

extension VirtualAccountModel {
    func edit(with editor: (any AccountModelEditor) -> Void) async throws(AccountEditError) -> Self {
        self
    }

    func analyticsParameters(with builder: any AccountsAnalyticsBuilder) -> [Analytics.ParameterKey: String] {
        [:]
    }

    func resolve<R>(using resolver: R) -> R.Result where R: AccountModelResolving {
        resolver.resolve(accountModel: self)
    }

    var icon: AccountModel.Icon {
        AccountModel.Icon(name: .virtualAccount, color: .clear)
    }

    // [REDACTED_TODO_COMMENT]
    var name: String {
        "Monerium"
    }

    var didChangePublisher: AnyPublisher<Void, Never> {
        .empty
    }
}
