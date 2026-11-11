//
//  TangemPayMoneyAccount.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import TangemPay

final class TangemPayMoneyAccount: TangemPayMoneyAccountModel {
    let customerId: String
    let walletModel: any WalletModel

    private let customerService: any CustomerInfoManagementService
    private let balanceProvider: TokenBalanceProvider
    private let bankingAccountSubject: CurrentValueSubject<TangemPayCustomerSummaryResponse.BankingAccount, Never>
    private let customerTariffPlanSubject: CurrentValueSubject<VisaCustomerInfoResponse.CustomerTariffPlan?, Never>
    private let bankCredentialsStorage = OSAllocatedUnfairLock<TangemPayBankCredentialsResponse?>(initialState: nil)

    private weak var account: (any TangemPayAccountModel)?

    init(
        customerId: String,
        bankingAccount: TangemPayCustomerSummaryResponse.BankingAccount,
        walletModel: any WalletModel,
        customerService: any CustomerInfoManagementService,
        account: (any TangemPayAccountModel)?
    ) {
        self.customerId = customerId
        self.walletModel = walletModel
        self.customerService = customerService
        self.account = account
        balanceProvider = TangemPayFiatTokenBalanceProvider(
            cryptoBalanceProvider: walletModel.totalTokenBalanceProvider
        )
        bankingAccountSubject = CurrentValueSubject(bankingAccount)
        customerTariffPlanSubject = CurrentValueSubject(nil)
    }

    // MARK: Public Interface

    var accountId: String? {
        bankingAccountSubject.value.id
    }

    var userWalletId: UserWalletId {
        walletModel.userWalletId
    }

    var tokenItem: TokenItem {
        walletModel.tokenItem
    }

    var walletAddresses: [String] {
        walletModel.allAddresses.map(\.value)
    }

    var explorerURL: URL? {
        walletModel.addresses.singleElement.flatMap {
            walletModel.exploreURL(for: $0.value, token: tokenItem.token)
        }
    }

    var activation: TangemPayCustomerSummaryResponse.Activation {
        bankingAccountSubject.value.activation
    }

    var activationPublisher: AnyPublisher<TangemPayCustomerSummaryResponse.Activation, Never> {
        bankingAccountSubject
            .map(\.activation)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var customerTariffPlan: VisaCustomerInfoResponse.CustomerTariffPlan? {
        customerTariffPlanSubject.value
    }

    var customerTariffPlanPublisher: AnyPublisher<VisaCustomerInfoResponse.CustomerTariffPlan?, Never> {
        customerTariffPlanSubject.eraseToAnyPublisher()
    }

    var fiatBalance: FormattedTokenBalanceType {
        balanceProvider.formattedBalanceType
    }

    var fiatBalancePublisher: AnyPublisher<FormattedTokenBalanceType, Never> {
        balanceProvider.formattedBalanceTypePublisher
    }

    var transactionHistoryPublisher: AnyPublisher<WalletModelTransactionHistoryState, Never> {
        walletModel.transactionHistoryPublisher
    }

    var canLoadMoreTransactionHistory: Bool {
        walletModel.canFetchHistory
    }

    var state: TangemPayLocalState? {
        account?.state
    }

    var statePublisher: AnyPublisher<TangemPayLocalState, Never> {
        account?.statePublisher ?? .empty
    }

    var bankCredentials: TangemPayBankCredentialsResponse? {
        bankCredentialsStorage.withLock { $0 }
    }

    func updateBalance() async {
        await walletModel.update(silent: false, options: .balances)
    }

    func loadTransactionHistory() async {
        await walletModel.updateTransactionHistory()
    }

    func updateTransactionHistory() async {
        await walletModel.update(silent: true, options: [.onChainTransactionHistory, .expressTransactionHistory])
    }

    func reloadTransactionHistory() async {
        await walletModel.clearHistory()
        await walletModel.updateTransactionHistory()
    }

    func refreshState() async {
        await account?.refreshState()
    }

    func renewSession(
        authorizingInteractor: TangemPayAuthorizing,
        completion: @escaping (TangemPayAuthorizationError?) -> Void
    ) {
        account?.renewSession(authorizingInteractor: authorizingInteractor, completion: completion)
    }

    func loadBankCredentials() async throws {
        guard bankCredentials == nil else {
            return
        }

        let customerInfo = try await customerService.loadCustomerInfo()

        guard let productInstanceId = customerInfo.collateralBankingAccountProductInstance?.id else {
            return
        }

        let credentials = try await customerService.getBankCredentials(productInstanceId: productInstanceId)
        bankCredentialsStorage.withLock { $0 = credentials }
    }

    // MARK: Internal Interface

    func update(bankingAccount: TangemPayCustomerSummaryResponse.BankingAccount) {
        if bankingAccount.id != accountId {
            bankCredentialsStorage.withLock { $0 = nil }
        }

        bankingAccountSubject.send(bankingAccount)
    }

    func update(customerTariffPlan: VisaCustomerInfoResponse.CustomerTariffPlan?) {
        customerTariffPlanSubject.send(customerTariffPlan)
    }
}
