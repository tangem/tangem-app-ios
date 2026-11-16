//
//  LendingAnalyticsLoggerTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
@testable import BlockchainSdk
@testable import Tangem

@Suite("Lending on Aave analytics")
struct LendingAnalyticsLoggerTests {
    @Test(
        "Amounts leave the device only as USD buckets",
        arguments: [
            ("49.99", "<50"),
            ("50", "50-250"),
            ("249.99", "50-250"),
            ("250", "250-1K"),
            ("1000", "1K-5K"),
            ("5000", "5K-25K"),
            ("25000", "25K-100K"),
            ("99999.99", "25K-100K"),
            ("100000", ">100K"),
        ]
    )
    func usdBucket(usd: String, bucket: String) throws {
        #expect(LendingAnalyticsLogger.usdBucket(try #require(Decimal(string: usd))) == bucket)
    }

    @Test(
        "Rates are sent as displayed percentages with two decimals",
        arguments: [
            (Decimal(245) / 10000, "2.45"),
            (Decimal(15) / 100, "15.00"),
        ]
    )
    func percent(fraction: Decimal, displayed: String) {
        #expect(LendingAnalyticsLogger.percent(fraction) == displayed)
    }

    @Test(
        "A deposit above the balance is a balance notice, one that only lacks the fee is a fee notice, as on screen",
        arguments: LendingAnalyticsLoggerTests.depositNotices
    )
    func depositNotice(amount: Decimal?, fee: Decimal?, balance: Decimal?, notice: LendingAnalyticsLogger.Notice?) {
        #expect(LendingAnalyticsLogger.Notice.deposit(amount: amount, fee: fee, balance: balance) == notice)
    }

    @Test(
        "A withdrawal the wallet can't pay the fee for is a fee notice, one above what's available is a balance notice, as on screen",
        arguments: LendingAnalyticsLoggerTests.withdrawNotices
    )
    func withdrawNotice(isAmountValid: Bool, isFeeCovered: Bool, notice: LendingAnalyticsLogger.Notice?) {
        #expect(LendingAnalyticsLogger.Notice.withdraw(isAmountValid: isAmountValid, isFeeCovered: isFeeCovered) == notice)
    }

    @Test("Opening the deposit sends its source and the current rate")
    func depositScreenOpened() {
        let (sut, spy) = makeSUT()

        sut.logDepositScreenOpened(source: .yieldPicker, currentApy: Decimal(24) / 1000)

        #expect(spy.logged == [Logged(.ethLendingDepositScreenOpened, [.source: "Yield Picker", .currentAPY: "2.40"])])
    }

    @Test("A sent deposit is signed, then submitted, with the upgrade flag")
    func sent() {
        let (sut, spy) = makeSUT(isWithUpgrade: true, usdPrice: 1000)

        sut.logSent(amount: Decimal(string: "0.5"))

        #expect(spy.logged == [
            Logged(.ethLendingTransactionSigned, [.transactionType: "Deposit", .withUpgrade: "true", .amountBucket: "250-1K"]),
            Logged(.ethLendingTransactionSubmitted, [.transactionType: "Deposit", .withUpgrade: "true"]),
        ])
    }

    @Test("A declined card tap is a cancelled signature, never a failure")
    func signCancelled() {
        let (sut, spy) = makeSUT()

        sut.logFailure(.userCancelled)

        #expect(spy.logged == [Logged(.ethLendingErrorSignCancelled, [.transactionType: "Deposit", .withUpgrade: "false"])])
    }

    @Test("A failed withdrawal sends the failure and the pop-up once each, then the button the user taps")
    func failure() {
        let (sut, spy) = makeSUT(transactionType: .withdraw)

        sut.logFailure(Self.sendError(code: 42))
        sut.logErrorPopupAction(.close)

        let params: [Analytics.ParameterKey: String] = [.transactionType: "Withdraw", .withUpgrade: "false", .errorCode: "42"]
        #expect(spy.logged == [
            Logged(.ethLendingErrorTransactionFailed, params),
            Logged(.ethLendingNoticeErrorPopup, params),
            Logged(.ethLendingButtonErrorPopup, [.transactionType: "Withdraw", .action: "Close"]),
        ])
    }

    @Test("Errors that never reach the network send nothing")
    func silentErrors() {
        let (sut, spy) = makeSUT()

        sut.logFailure(.feeNotFound)
        sut.logFailure(.informationRelevanceServiceFeeWasIncreased)

        #expect(spy.logged.isEmpty)
    }

    @Test("Withdraw screen marks capped liquidity, and leaves out what it couldn't read")
    func withdrawScreenOpened() {
        let (sut, spy) = makeSUT(transactionType: .withdraw, usdPrice: 2000)
        let (noPriceSUT, noPriceSpy) = makeSUT(transactionType: .withdraw, usdPrice: nil)

        sut.logWithdrawScreenOpened(positionBalance: 1, availableToWithdraw: Decimal(string: "0.5"))
        sut.logWithdrawScreenOpened(positionBalance: 1, availableToWithdraw: 1)
        noPriceSUT.logWithdrawScreenOpened(positionBalance: 1, availableToWithdraw: nil)

        #expect(spy.logged == [
            Logged(.ethLendingWithdrawScreenOpened, [.positionBucket: "1K-5K", .liquidityCapped: "true"]),
            Logged(.ethLendingWithdrawScreenOpened, [.positionBucket: "1K-5K", .liquidityCapped: "false"]),
        ])
        #expect(noPriceSpy.logged == [Logged(.ethLendingWithdrawScreenOpened, [:])])
    }

    @Test("Fee speed is sent only when the speed changes, with the screen the selector was opened from")
    func feeSpeed() {
        let (sut, spy) = makeSUT(transactionType: .withdraw)

        sut.logFeeSelected(.market)
        sut.logFeeSelected(.fast)
        sut.logFeeSelected(.fast)
        sut.feeSelectorScreen = .confirm
        sut.logFeeSelected(.market)

        #expect(spy.logged == [
            Logged(.ethLendingButtonFeeSpeed, [.feeSpeed: FeeOption.fast.analyticsValue.rawValue, .screen: "Withdraw"]),
            Logged(.ethLendingButtonFeeSpeed, [.feeSpeed: FeeOption.market.analyticsValue.rawValue, .screen: "Confirm"]),
        ])
    }

    @Test("Fee speed compares against the speed selected when the selector opened, so confirming a preselected Fast sends nothing")
    func feeSpeedFromPreselectedOption() {
        let (sut, spy) = makeSUT(transactionType: .deposit)

        sut.startFeeSelection(on: .confirm, from: .fast)
        sut.logFeeSelected(.fast)
        sut.logFeeSelected(.market)

        #expect(spy.logged == [
            Logged(.ethLendingButtonFeeSpeed, [.feeSpeed: FeeOption.market.analyticsValue.rawValue, .screen: "Confirm"]),
        ])
    }

    @Test("Finishing a fee selection sends the fee speed and passes the selection on")
    func feeSelectorOutput() {
        let (logger, spy) = makeSUT(transactionType: .withdraw)
        let output = FeeSelectorOutputSpy()
        let sut = LendingFeeSelectorOutput(output: output, analyticsLogger: logger)

        sut.userDidFinishSelection(feeProviderID: output.providerID, feeOption: .fast)

        #expect(output.selections == [.fast])
        #expect(spy.logged == [
            Logged(.ethLendingButtonFeeSpeed, [.feeSpeed: FeeOption.fast.analyticsValue.rawValue, .screen: "Withdraw"]),
        ])
    }

    @Test("Amount controls report the amount screen")
    func amountControls() {
        let (sut, spy) = makeSUT()

        sut.logMax()
        sut.logPercent(25)
        sut.logCurrencyToggled(to: .fiat)
        sut.logNotice(.insufficientFee)

        #expect(spy.logged == [
            Logged(.ethLendingButtonMax, [.screen: "Deposit"]),
            Logged(.ethLendingButtonPercent, [.percent: "25", .screen: "Deposit"]),
            Logged(.ethLendingButtonCurrencyToggle, [.displayCurrency: "Fiat", .screen: "Deposit"]),
            Logged(.ethLendingNoticeInsufficientFee, [.screen: "Deposit"]),
        ])
    }
}

// MARK: - Helpers

private extension LendingAnalyticsLoggerTests {
    func makeSUT(
        transactionType: LendingAnalyticsLogger.TransactionType = .deposit,
        isWithUpgrade: Bool = false,
        usdPrice: Decimal? = nil
    ) -> (LendingAnalyticsLogger, AnalyticsSinkSpy) {
        let spy = AnalyticsSinkSpy()
        let sut = LendingAnalyticsLogger(
            transactionType: transactionType,
            isWithUpgrade: isWithUpgrade,
            usdPrice: { usdPrice },
            sink: spy.record
        )
        return (sut, spy)
    }

    static func sendError(code: Int) -> TransactionDispatcherResult.Error {
        let blockchain = Blockchain.ethereum(testnet: false)
        let transaction = Transaction(
            amount: Amount(with: blockchain, type: .coin, value: 0),
            fee: Fee(Amount(with: blockchain, type: .coin, value: Decimal(1) / 1000)),
            sourceAddress: "source",
            destinationAddress: "module",
            changeAddress: "source"
        )

        return .sendTxError(transaction: .transfer(transaction), error: SendTxError(error: SendErrorStub(errorCode: code)))
    }

    static var depositNotices: [(Decimal?, Decimal?, Decimal?, LendingAnalyticsLogger.Notice?)] {
        [
            (2, 0.01, 1, .insufficientBalance),
            (1, 0.01, 1, .insufficientFee),
            (Decimal(5) / 10, 0.01, 1, nil),
            (nil, 2, 1, .insufficientFee),
            (nil, 0.01, 1, nil),
            (1, nil, nil, nil),
        ]
    }

    static var withdrawNotices: [(Bool, Bool, LendingAnalyticsLogger.Notice?)] {
        [
            (true, false, .insufficientFee),
            (false, false, .insufficientFee),
            (false, true, .insufficientBalance),
            (true, true, nil),
        ]
    }
}

// MARK: - Stubs

private struct Logged: Equatable {
    let event: Analytics.Event
    let params: [Analytics.ParameterKey: String]

    init(_ event: Analytics.Event, _ params: [Analytics.ParameterKey: String]) {
        self.event = event
        self.params = params
    }
}

private final class FeeSelectorOutputSpy: FeeSelectorOutput {
    let providerID = TokenFeeProviderID(
        feeTokenItem: .blockchain(.init(.ethereum(testnet: false), derivationPath: nil)),
        payer: .user
    )

    private(set) var selections: [FeeOption] = []

    func userDidFinishSelection(feeProviderID: TokenFeeProviderID, feeOption: FeeOption) {
        selections.append(feeOption)
    }
}

private final class AnalyticsSinkSpy {
    private let state = OSAllocatedUnfairLock(initialState: [Logged]())

    var logged: [Logged] {
        state.withLock { $0 }
    }

    func record(_ event: Analytics.Event, _ params: [Analytics.ParameterKey: String]) {
        state.withLock { $0.append(Logged(event, params)) }
    }
}

private struct SendErrorStub: UniversalError {
    let errorCode: Int
}
