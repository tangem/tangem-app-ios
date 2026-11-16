//
//  TangemPayMoneyAccountModelAdapter.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemLocalization
import TangemPay

final class TangemPayMoneyAccountModelAdapter: TangemPayAccountModel {
    private let moneyAccount: any TangemPayMoneyAccountModel

    init(moneyAccount: any TangemPayMoneyAccountModel) {
        self.moneyAccount = moneyAccount
    }

    var id: TangemPayAccountId {
        TangemPayAccountId(userWalletId: moneyAccount.userWalletId)
    }

    var name: String {
        Localization.moneyAccountMainName
    }

    var icon: AccountModel.StandaloneIcon {
        .moneyAccount
    }

    var state: TangemPayLocalState? {
        moneyAccount.state
    }

    var statePublisher: AnyPublisher<TangemPayLocalState, Never> {
        moneyAccount.statePublisher
    }

    var moneyAccountState: TangemPayMoneyAccountState? {
        nil
    }

    var moneyAccountStatePublisher: AnyPublisher<TangemPayMoneyAccountState?, Never> {
        .just(output: nil)
    }

    var moneyAccountPublisher: AnyPublisher<(any TangemPayMoneyAccountModel)?, Never> {
        .just(output: nil)
    }

    var lastKnownTangemPayAccount: TangemPayAccount? {
        nil
    }

    var lastKnownMoneyAccount: (any TangemPayMoneyAccountModel)? {
        nil
    }

    var customerId: String? {
        moneyAccount.customerId
    }

    func refreshState() async {
        await moneyAccount.refreshState()
    }

    func renewSession(
        authorizingInteractor: TangemPayAuthorizing,
        completion: @escaping (TangemPayAuthorizationError?) -> Void
    ) {
        moneyAccount.renewSession(authorizingInteractor: authorizingInteractor, completion: completion)
    }

    func resolve<R>(using resolver: R) -> R.Result where R: AccountModelResolving {
        resolver.resolve(accountModel: self)
    }
}
