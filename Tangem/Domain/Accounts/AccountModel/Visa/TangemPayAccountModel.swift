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

protocol TangemPayAccountModel: BaseAccountModel where Icon == AccountModel.StandaloneIcon {
    var state: TangemPayLocalState? { get }
    var statePublisher: AnyPublisher<TangemPayLocalState, Never> { get }

    /// Last successfully loaded `TangemPayAccount`. Retained across transient error states
    /// (`.unavailable`, `.syncNeeded`) so the UI can keep navigating to the Payment Account
    /// screen and show cached balance/transactions while the backend is unavailable.
    var lastKnownTangemPayAccount: TangemPayAccount? { get }

    var customerId: String? { get }

    func refreshState() async
    func renewSession(
        authorizingInteractor: TangemPayAuthorizing,
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

    var icon: AccountModel.StandaloneIcon {
        .tangemPay
    }

    var name: String {
        Localization.tangempayPaymentAccount
    }

    var didChangePublisher: AnyPublisher<Void, Never> {
        .empty
    }
}
