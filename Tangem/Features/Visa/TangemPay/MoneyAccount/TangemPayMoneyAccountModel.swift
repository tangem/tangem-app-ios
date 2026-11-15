//
//  TangemPayMoneyAccountModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import TangemPay

protocol TangemPayMoneyAccountModel: AnyObject, WalletModelTransactionHistoryAddressesProvider {
    var customerId: String { get }
    var accountId: String? { get }
    var userWalletId: UserWalletId { get }

    var walletModel: any WalletModel { get }
    var tokenItem: TokenItem { get }
    var explorerURL: URL? { get }

    var activation: TangemPayCustomerSummaryResponse.Activation { get }
    var activationPublisher: AnyPublisher<TangemPayCustomerSummaryResponse.Activation, Never> { get }

    var customerTariffPlan: VisaCustomerInfoResponse.CustomerTariffPlan? { get }
    var customerTariffPlanPublisher: AnyPublisher<VisaCustomerInfoResponse.CustomerTariffPlan?, Never> { get }

    var fiatBalance: FormattedTokenBalanceType { get }
    var fiatBalancePublisher: AnyPublisher<FormattedTokenBalanceType, Never> { get }

    var transactionHistoryPublisher: AnyPublisher<WalletModelTransactionHistoryState, Never> { get }
    var canLoadMoreTransactionHistory: Bool { get }

    var state: TangemPayLocalState? { get }
    var statePublisher: AnyPublisher<TangemPayLocalState, Never> { get }

    func updateBalance() async
    func loadTransactionHistory() async
    func updateTransactionHistory() async
    func reloadTransactionHistory() async

    func refreshState() async
    func renewSession(
        authorizingInteractor: TangemPayAuthorizing,
        completion: @escaping (TangemPayAuthorizationError?) -> Void
    )
}
