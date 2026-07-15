//
//  TransactionHistoryMapperWarningTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemLocalization
@testable import BlockchainSdk
@testable import Tangem
@testable import TangemExpress

@Suite("TransactionHistoryMapper Express verification warning")
struct TransactionHistoryMapperWarningTests {
    @Test("Exchange in .verifying surfaces the verification warning")
    func exchangeVerifyingWarns() {
        let warning = makeWarning(for: .exchange(exchangeInfo(status: .verifying)))
        #expect(warning == Localization.expressExchangeNotificationVerificationTitle)
    }

    @Test(
        "Exchange in a non-verifying status has no warning",
        arguments: [ExpressTransactionStatus.created, .exchanging, .sending, .finished, .failed, .refunded]
    )
    func exchangeNonVerifyingHasNoWarning(status: ExpressTransactionStatus) {
        #expect(makeWarning(for: .exchange(exchangeInfo(status: status))) == nil)
    }

    @Test("Onramp in .verifying surfaces the verification warning")
    func onrampVerifyingWarns() {
        let warning = makeWarning(for: .onramp(onrampInfo(status: .verifying)))
        #expect(warning == Localization.expressExchangeNotificationVerificationTitle)
    }

    @Test(
        "Onramp in a non-verifying status has no warning",
        arguments: [OnrampTransactionStatus.created, .waitingForPayment, .paymentProcessing, .paid, .sending, .finished, .failed]
    )
    func onrampNonVerifyingHasNoWarning(status: OnrampTransactionStatus) {
        #expect(makeWarning(for: .onramp(onrampInfo(status: status))) == nil)
    }

    @Test("A plain transfer (no Express extra info) has no warning")
    func plainTransferHasNoWarning() {
        #expect(makeWarning(for: nil) == nil)
    }
}

// MARK: - Helpers

private extension TransactionHistoryMapperWarningTests {
    func makeSUT() -> Tangem.TransactionHistoryMapper {
        Tangem.TransactionHistoryMapper(
            currencySymbol: "ETH",
            addressesProvider: StubWarningAddressesProvider(walletAddresses: ["0xSource"]),
            showSign: true,
            isToken: false
        )
    }

    func makeWarning(for extraInfo: TransactionHistoryExpressExtraInfo?) -> String? {
        makeSUT().mapTransactionViewModel(makeRecord(extraInfo: extraInfo)).warning
    }

    func makeRecord(extraInfo: TransactionHistoryExpressExtraInfo?) -> TransactionRecord {
        let record = TransactionRecord(
            hash: "hash",
            index: 0,
            source: .single(.init(address: "0xSource", amount: 1)),
            destination: .single(.init(address: .user("0xDestination"), amount: 1)),
            fee: Fee(Amount(type: .coin, currencySymbol: "ETH", value: 0, decimals: 18)),
            status: .confirmed,
            isOutgoing: true,
            type: .transfer,
            date: Date(timeIntervalSince1970: 1_700_000_000),
            tokenTransfers: [],
            nonce: nil
        )

        return extraInfo.map { record.withExpressExtraInfo($0) } ?? record
    }

    func exchangeInfo(status: ExpressTransactionStatus) -> ExchangeTransactionInfo {
        ExchangeTransactionInfo(
            transaction: ExpressMergeTestDataFactory.exchangeTransaction(
                txId: "tx",
                status: status,
                fromAddress: nil,
                payInAddress: "0xIn",
                payInHash: nil,
                payOutAddress: "0xOut",
                payOutHash: nil,
                fromCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
                fromAmount: 1,
                fromActualAmount: nil,
                toCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
                toAmount: 1,
                toActualAmount: nil,
                refund: nil,
                createdAt: ExpressMergeTestDataFactory.baseDate,
                updatedAt: ExpressMergeTestDataFactory.baseDate
            ),
            provider: nil,
            cryptoCurrencies: [:]
        )
    }

    func onrampInfo(status: OnrampTransactionStatus) -> OnrampTransactionInfo {
        OnrampTransactionInfo(
            onrampTransaction: ExpressMergeTestDataFactory.onrampTransaction(
                txId: "tx",
                status: status,
                payOutAddress: "0xOut",
                payOutHash: nil,
                toCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
                toAmount: 1,
                toActualAmount: nil,
                createdAt: ExpressMergeTestDataFactory.baseDate,
                updatedAt: ExpressMergeTestDataFactory.baseDate
            ),
            provider: nil,
            fiatCurrency: nil,
            cryptoCurrencies: [:]
        )
    }
}

// MARK: - Stubs

private struct StubWarningAddressesProvider: WalletModelTransactionHistoryAddressesProvider {
    let walletAddresses: [String]
}
