//
//  EarnWithdrawalResultViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemTestKit
@testable import BlockchainSdk
@testable import Tangem

@Suite("Earn withdrawal result")
final class EarnWithdrawalResultViewModelTests: LeakTrackingTestSuite {
    @Test("The title names the status and the withdrawn amount", arguments: [
        (EarnWithdrawalResultContentView.Status.withdrawn, "Withdrawn %@"),
        (.inProgress, "Withdrawal in progress\n%@"),
    ])
    func title(status: EarnWithdrawalResultContentView.Status, format: String) {
        let (sut, _) = makeSUT(status: status)

        #expect(sut.state.title == String(format: format, withdrawnAmount))
    }

    @Test("The screen shows the fiat amount with the send date, the product's withdrawal period and the fee in its own token")
    func state() {
        let (sut, _) = makeSUT(withdrawalPeriod: "Up to 48 hours", fiatAmount: "$2,130.88")

        #expect(sut.state == EarnWithdrawalResultContentView.StateModel(
            status: .withdrawn,
            title: "Withdrawn \(withdrawnAmount)",
            summary: "$2,130.88 · 2 May 2024",
            withdrawalPeriod: "Up to 48 hours",
            fee: EarnWithdrawalResultContentView.Fee(symbol: "USDT", value: "$1.40"),
            hasTransactionLink: true
        ))
    }

    @Test("Without a fiat rate for the withdrawn token the summary shows only the send date")
    func summaryWithoutFiat() {
        let (sut, _) = makeSUT(fiatAmount: nil)

        #expect(sut.state.summary == "2 May 2024")
    }

    @Test("A fee without a fiat rate is shown in crypto, without a token badge repeating its symbol")
    func feeWithoutFiat() {
        let (sut, _) = makeSUT(fee: FormattedFeeComponents(cryptoFee: "1.4 USDT", fiatFee: nil))

        #expect(sut.state.fee == EarnWithdrawalResultContentView.Fee(symbol: nil, value: "1.4 USDT"))
    }

    @Test("Explore and Share open the transaction link, Done closes the screen")
    func actions() throws {
        let url = try #require(URL(string: "https://etherscan.io/tx/0x1"))
        let (sut, router) = makeSUT(transactionURL: url)

        sut.handle(.explore)
        sut.handle(.share)
        sut.handle(.done)

        #expect(router.calls == [.explorer(url), .share(url), .close])
    }

    @Test("Without a transaction link Explore and Share do nothing")
    func noTransactionLink() {
        let (sut, router) = makeSUT(transactionURL: nil)

        sut.handle(.explore)
        sut.handle(.share)

        #expect(!sut.state.hasTransactionLink)
        #expect(router.calls.isEmpty)
    }
}

// MARK: - Helpers

private extension EarnWithdrawalResultViewModelTests {
    var withdrawnAmount: String {
        SendCryptoValueFormatter(decimals: 18, currencySymbol: "ETH", trimFractions: true).string(from: Decimal(5) / 10)
    }

    func makeSUT(
        status: EarnWithdrawalResultContentView.Status = .withdrawn,
        withdrawalPeriod: String = "Usually instant",
        fiatAmount: String? = nil,
        fee: FormattedFeeComponents = FormattedFeeComponents(cryptoFee: "1.4 USDT", fiatFee: "$1.40"),
        transactionURL: URL? = URL(string: "https://etherscan.io/tx/0x1")
    ) -> (EarnWithdrawalResultViewModel, EarnWithdrawalResultRouterSpy) {
        let router = trackForMemoryLeaks(EarnWithdrawalResultRouterSpy())
        let sut = EarnWithdrawalResultViewModel(
            input: EarnWithdrawalResultViewModel.Input(
                status: status,
                tokenItem: .blockchain(.init(.ethereum(testnet: false), derivationPath: nil)),
                amount: Decimal(5) / 10,
                sentDate: Date(timeIntervalSince1970: 1_714_642_860),
                withdrawalPeriod: withdrawalPeriod,
                feeTokenItem: .token(
                    .init(name: "Tether", symbol: "USDT", contractAddress: "0xUSDT", decimalCount: 6, id: nil),
                    .init(.ethereum(testnet: false), derivationPath: nil)
                ),
                feeAmount: Decimal(14) / 10,
                transactionURL: transactionURL
            ),
            router: router,
            formatFiatAmount: { _, _ in fiatAmount },
            feeFormatter: FeeFormatterStub(components: fee),
            dateFormatter: makeDateFormatter()
        )

        return (trackForMemoryLeaks(sut), router)
    }

    func makeDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "d MMM yyyy"
        return formatter
    }
}

// MARK: - Stubs

private final class EarnWithdrawalResultRouterSpy: EarnWithdrawalResultRoutable {
    enum Call: Equatable {
        case explorer(URL)
        case share(URL)
        case close
    }

    private(set) var calls: [Call] = []

    func openExplorer(url: URL) {
        calls.append(.explorer(url))
    }

    func openShareSheet(url: URL) {
        calls.append(.share(url))
    }

    func closeWithdrawalResult() {
        calls.append(.close)
    }
}

private struct FeeFormatterStub: FeeFormatter {
    let components: FormattedFeeComponents

    func formattedFeeComponents(
        fee: Decimal,
        currencySymbol: String,
        currencyId: String?,
        isFeeApproximate: Bool,
        formattingOptions: BalanceFormattingOptions
    ) -> FormattedFeeComponents {
        components
    }

    func format(fee: Decimal, currencySymbol: String, currencyId: String?, isFeeApproximate: Bool) -> String {
        components.cryptoFee
    }
}
