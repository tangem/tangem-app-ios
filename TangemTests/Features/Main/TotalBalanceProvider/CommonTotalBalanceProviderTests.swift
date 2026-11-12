//
//  CommonTotalBalanceProviderTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Testing
import TangemFoundation
import TangemPay
@testable import Tangem

@Suite("Main screen total balance")
struct CommonTotalBalanceProviderTests {
    @Test("A Polymarket account adds its total, open positions included, not just the available cash")
    func polymarketAddsItsTotal() {
        let sut = makeSUT(polymarketState: .active, polymarketAvailable: 10, polymarketTotal: 25)

        #expect(sut.totalBalance == .loaded(balance: 30))
    }

    @Test("A Polymarket account the user cannot see adds nothing")
    func hiddenPolymarketAddsNothing() {
        let sut = makeSUT(polymarketState: .unavailable, polymarketAvailable: 10, polymarketTotal: 25)

        #expect(sut.totalBalance == .loaded(balance: 5))
    }

    @Test("Only an open Money account adds the balance of its wallet", arguments: [
        (status: "COMPLETED", total: 6.96 as Decimal),
        (status: "PROCESSING", total: 5 as Decimal),
        (status: "FAILED", total: 5 as Decimal),
        (status: "DEACTIVATED", total: 5 as Decimal),
    ])
    func onlyOpenMoneyAccountAddsItsBalance(status: String, total: Decimal) throws {
        let tangemPayAccount = try TangemPayAccountModelStub(moneyAccount: makeMoneyAccount(status: status, balance: 1.96))
        let sut = makeSUT(tangemPayAccount: tangemPayAccount)

        #expect(sut.totalBalance == .loaded(balance: total))
    }

    @Test("Without a Money account the total is the rest of the wallet")
    func noMoneyAccountAddsNothing() {
        let sut = makeSUT(tangemPayAccount: TangemPayAccountModelStub(moneyAccount: nil))

        #expect(sut.totalBalance == .loaded(balance: 5))
    }

    @Test("A Money account joins the total once it opens")
    func moneyAccountJoinsTheTotalOnceOpen() throws {
        let moneyAccount = try makeMoneyAccount(status: "PROCESSING", balance: 1.96)
        let sut = makeSUT(tangemPayAccount: TangemPayAccountModelStub(moneyAccount: moneyAccount))

        try moneyAccount.setActivation(status: "COMPLETED")

        #expect(sut.totalBalance == .loaded(balance: 6.96))
    }

    @Test("A Money account the Tangem Pay account drops leaves the total")
    func removedMoneyAccountLeavesTheTotal() throws {
        let tangemPayAccount = try TangemPayAccountModelStub(moneyAccount: makeMoneyAccount(status: "COMPLETED", balance: 1.96))
        let sut = makeSUT(tangemPayAccount: tangemPayAccount)

        tangemPayAccount.moneyAccountSubject.send(nil)

        #expect(sut.totalBalance == .loaded(balance: 5))
    }
}

// MARK: - Helpers

private extension CommonTotalBalanceProviderTests {
    func makeSUT(
        cryptoBalance: Decimal = 5,
        polymarketState: PolymarketAccountState,
        polymarketAvailable: Decimal,
        polymarketTotal: Decimal
    ) -> CommonTotalBalanceProvider {
        let cryptoTotalBalanceProvider = TotalBalanceProviderTestsMock()
        cryptoTotalBalanceProvider.totalBalance = .loaded(balance: cryptoBalance)
        cryptoTotalBalanceProvider.sendUpdate()

        let cryptoAccount = CryptoAccountModelMock(
            isMainAccount: true,
            totalBalanceProvider: cryptoTotalBalanceProvider,
            onArchive: { _ in }
        )

        let polymarketAccount = PolymarketAccountModelStub(
            state: polymarketState,
            fiatAvailableBalanceProvider: TokenBalanceProviderTestsMock(balance: polymarketAvailable),
            fiatTotalTokenBalanceProvider: TokenBalanceProviderTestsMock(balance: polymarketTotal)
        )

        let accountModelsManager = AccountModelsManagerStub(accounts: [
            .standard(.single(cryptoAccount)),
            .polymarket(polymarketAccount),
        ])

        return CommonTotalBalanceProvider(
            accountModelsManager: accountModelsManager,
            analyticsLogger: AccountTotalBalanceProviderAnalyticsLogger()
        )
    }

    func makeSUT(cryptoBalance: Decimal = 5, tangemPayAccount: TangemPayAccountModelStub) -> CommonTotalBalanceProvider {
        let cryptoTotalBalanceProvider = TotalBalanceProviderTestsMock()
        cryptoTotalBalanceProvider.totalBalance = .loaded(balance: cryptoBalance)
        cryptoTotalBalanceProvider.sendUpdate()

        let cryptoAccount = CryptoAccountModelMock(
            isMainAccount: true,
            totalBalanceProvider: cryptoTotalBalanceProvider,
            onArchive: { _ in }
        )

        let accountModelsManager = AccountModelsManagerStub(accounts: [
            .standard(.single(cryptoAccount)),
            .tangemPay(tangemPayAccount),
        ])

        return CommonTotalBalanceProvider(
            accountModelsManager: accountModelsManager,
            analyticsLogger: AccountTotalBalanceProviderAnalyticsLogger()
        )
    }

    func makeMoneyAccount(status: String, balance: Decimal) throws -> TangemPayMoneyAccountModelStub {
        try TangemPayMoneyAccountModelStub(
            walletModel: WalletModelTestsMock(
                tokenItem: TangemPayUtilities.usdcTokenItem,
                isEmpty: false,
                fiatBalance: balance
            ),
            status: status
        )
    }
}

// MARK: - Stubs

private final class TangemPayAccountModelStub: TangemPayAccountModel {
    let id = TangemPayAccountId(userWalletId: UserWalletId(value: Data([0x01, 0x02, 0x03])))
    let moneyAccountSubject: CurrentValueSubject<(any TangemPayMoneyAccountModel)?, Never>

    init(moneyAccount: (any TangemPayMoneyAccountModel)?) {
        moneyAccountSubject = CurrentValueSubject(moneyAccount)
    }

    var moneyAccountState: TangemPayMoneyAccountState? { moneyAccountSubject.value.map { .active($0) } }
    var moneyAccountStatePublisher: AnyPublisher<TangemPayMoneyAccountState?, Never> { .just(output: moneyAccountState) }
    var moneyAccountPublisher: AnyPublisher<(any TangemPayMoneyAccountModel)?, Never> { moneyAccountSubject.eraseToAnyPublisher() }

    var state: TangemPayLocalState? { .loading }
    var statePublisher: AnyPublisher<TangemPayLocalState, Never> { .just(output: .loading) }
    var lastKnownTangemPayAccount: TangemPayAccount? { nil }
    var lastKnownMoneyAccount: (any TangemPayMoneyAccountModel)? { moneyAccountSubject.value }
    var customerId: String? { nil }

    func refreshState() async {}

    func renewSession(
        authorizingInteractor: TangemPayAuthorizing,
        completion: @escaping (TangemPayAuthorizationError?) -> Void
    ) {}

    func resolve<R>(using resolver: R) -> R.Result where R: AccountModelResolving {
        resolver.resolve(accountModel: self)
    }
}

private final class TangemPayMoneyAccountModelStub: TangemPayMoneyAccountModel {
    let walletModel: any WalletModel
    private let activationSubject: CurrentValueSubject<TangemPayCustomerSummaryResponse.Activation, Never>

    init(walletModel: any WalletModel, status: String) throws {
        self.walletModel = walletModel
        activationSubject = try CurrentValueSubject(Self.makeActivation(status: status))
    }

    var activation: TangemPayCustomerSummaryResponse.Activation { activationSubject.value }

    func setActivation(status: String) throws {
        try activationSubject.send(Self.makeActivation(status: status))
    }

    private static func makeActivation(status: String) throws -> TangemPayCustomerSummaryResponse.Activation {
        try JSONDecoder().decode(
            TangemPayCustomerSummaryResponse.Activation.self,
            from: Data(#"{"status":"\#(status)"}"#.utf8)
        )
    }

    var customerId: String { "customer" }
    var accountId: String? { nil }
    var userWalletId: UserWalletId { walletModel.userWalletId }
    var tokenItem: TokenItem { walletModel.tokenItem }
    var explorerURL: URL? { nil }
    var activationPublisher: AnyPublisher<TangemPayCustomerSummaryResponse.Activation, Never> { activationSubject.eraseToAnyPublisher() }
    var customerTariffPlan: VisaCustomerInfoResponse.CustomerTariffPlan? { nil }
    var customerTariffPlanPublisher: AnyPublisher<VisaCustomerInfoResponse.CustomerTariffPlan?, Never> { .just(output: nil) }
    var fiatBalance: FormattedTokenBalanceType { .loaded("") }
    var fiatBalancePublisher: AnyPublisher<FormattedTokenBalanceType, Never> { .just(output: fiatBalance) }
    var transactionHistoryPublisher: AnyPublisher<WalletModelTransactionHistoryState, Never> { .empty }
    var canLoadMoreTransactionHistory: Bool { false }
    var state: TangemPayLocalState? { nil }
    var statePublisher: AnyPublisher<TangemPayLocalState, Never> { .empty }
    var bankCredentials: TangemPayBankCredentialsResponse? { nil }
    var walletAddresses: [String] { [] }

    func updateBalance() async {}
    func loadTransactionHistory() async {}
    func updateTransactionHistory() async {}
    func reloadTransactionHistory() async {}
    func loadBankCredentials() async throws {}
    func refreshState() async {}

    func renewSession(
        authorizingInteractor: TangemPayAuthorizing,
        completion: @escaping (TangemPayAuthorizationError?) -> Void
    ) {}
}
