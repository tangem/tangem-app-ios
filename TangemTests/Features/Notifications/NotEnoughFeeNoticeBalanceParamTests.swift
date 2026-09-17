//
//  NotEnoughFeeNoticeBalanceParamTests.swift
//  TangemTests
//
//  Covers the `Balance` parameter of the "Notice - Not Enough Fee" analytics events ([REDACTED_INFO]): the fee-currency
//  balance the shortage was judged against is reported as `Empty` when it is zero and `Full` otherwise, and the
//  parameter is left out entirely when the notification was built without a balance to report.
//

import Foundation
import Testing
import BlockchainSdk
@testable import Tangem

@Suite("Notice - Not Enough Fee — Balance parameter")
struct NotEnoughFeeNoticeBalanceParamTests {
    private let usdtTokenItem: TokenItem = .token(
        .init(name: "USDT", symbol: "USDT", contractAddress: "0xUSDT", decimalCount: 6),
        .init(.ethereum(testnet: false), derivationPath: nil)
    )

    @Test("Zero fee-currency balance is reported as Empty")
    func zeroBalanceIsEmpty() {
        #expect(Analytics.ParameterValue.balanceState(for: .zero) == .empty)
    }

    @Test("Any non-zero fee-currency balance is reported as Full", arguments: [0.000001, 1, 1_000_000] as [Decimal])
    func nonZeroBalanceIsFull(balance: Decimal) {
        #expect(Analytics.ParameterValue.balanceState(for: balance) == .full)
    }

    @Test("[Token / Send] notice reports the fee-currency balance state")
    func sendNoticeReportsBalance() throws {
        let event = SendNotificationEvent.validationErrorEvent(makeInsufficientFeeEvent(feeCurrencyBalance: 0.5))

        #expect(event.analyticsEvent == .sendNoticeNotEnoughFee)
        #expect(event.analyticsParams[.balance] == Analytics.ParameterValue.full.rawValue)
        #expect(event.analyticsParams[.token] == usdtTokenItem.currencySymbol)
    }

    @Test("[Token] notice reports the fee-currency balance state")
    func tokenNoticeReportsBalance() throws {
        let configuration = try makeConfiguration(feeCurrencyBalance: .zero)
        let event = TokenNotificationEvent.notEnoughFeeForTransaction(configuration: configuration)

        #expect(event.analyticsEvent == .tokenNoticeNotEnoughFee)
        #expect(event.analyticsParams[.balance] == Analytics.ParameterValue.empty.rawValue)
        #expect(event.analyticsParams[.token] == usdtTokenItem.currencySymbol)
    }

    // MARK: - Helpers

    private func makeInsufficientFeeEvent(feeCurrencyBalance: Decimal) -> ValidationErrorEvent {
        BlockchainSDKNotificationMapper(tokenItem: usdtTokenItem)
            .mapToInsufficientBalanceForFeeEvent(feeCurrencyBalance: feeCurrencyBalance)
    }

    private func makeConfiguration(feeCurrencyBalance: Decimal) throws -> SendingRestrictions.NotEnoughFeeConfiguration {
        guard case .insufficientBalanceForFee(let configuration) = makeInsufficientFeeEvent(feeCurrencyBalance: feeCurrencyBalance) else {
            throw TestError.unexpectedEvent
        }

        return configuration
    }

    private enum TestError: Error {
        case unexpectedEvent
    }
}
