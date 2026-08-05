//
//  TransactionHistoryMapperWarningTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
@testable import Tangem
@testable import TangemExpress

@Suite("TransactionHistoryMapper Express warning")
struct TransactionHistoryMapperWarningTests {
    @Test("Exchange surfaces the matching warning per status", arguments: ExpressTransactionStatus.allCases)
    func exchangeWarning(status: ExpressTransactionStatus) {
        let warning = makeWarning(for: .exchange(exchangeInfo(status: status)))
        #expect(warning == Self.expectedWarning(for: status))
    }

    @Test("Onramp surfaces the matching warning per status", arguments: OnrampTransactionStatus.allCases)
    func onrampWarning(status: OnrampTransactionStatus) {
        let warning = makeWarning(for: .onramp(onrampInfo(status: status)))
        #expect(warning == Self.expectedWarning(for: status))
    }

    @Test("A plain transfer (no Express extra info) has no warning")
    func plainTransferHasNoWarning() {
        #expect(makeWarning(for: nil) == nil)
    }
}

// MARK: - Expected behavior

private extension TransactionHistoryMapperWarningTests {
    static func expectedWarning(for status: ExpressTransactionStatus) -> TransactionViewModel.Warning? {
        switch status {
        case .verifying:
            return .verifying
        case .paused:
            return .paused
        case .unknown,
             .preview,
             .created,
             .exchangeTxSent,
             .waiting,
             .waitingTxHash,
             .expired,
             .confirming,
             .exchanging,
             .sending,
             .finished,
             .failed,
             .txFailed,
             .refunded:
            return nil
        }
    }

    static func expectedWarning(for status: OnrampTransactionStatus) -> TransactionViewModel.Warning? {
        switch status {
        case .verifying:
            return .verifying
        case .paused:
            return .paused
        case .unknown,
             .created,
             .expired,
             .waitingForPayment,
             .paymentProcessing,
             .failed,
             .paid,
             .sending,
             .refunding,
             .refunded,
             .finished:
            return nil
        }
    }
}

// MARK: - Helpers

private extension TransactionHistoryMapperWarningTests {
    func makeSUT() -> TransactionHistoryMapper {
        TransactionHistoryMapper(
            currencySymbol: "ETH",
            addressesProvider: StubWarningAddressesProvider(walletAddresses: ["0xSource"]),
            showSign: true,
            isToken: false
        )
    }

    func makeWarning(for extraInfo: TransactionHistoryExpressExtraInfo?) -> TransactionViewModel.Warning? {
        makeSUT().mapTransactionViewModel(makeRecord(extraInfo: extraInfo)).warning
    }

    func makeRecord(extraInfo: TransactionHistoryExpressExtraInfo?) -> TransactionRecord {
        let record = TransactionRecord(
            hash: "hash",
            index: 0,
            source: .single(.init(address: "0xSource", amount: 1)),
            destination: .single(.init(address: .user("0xDestination"), amount: 1)),
            fee: ExpressMergeTestDataFactory.ethereumToken.zeroFee,
            status: .confirmed,
            isOutgoing: true,
            type: .transfer,
            date: ExpressMergeTestDataFactory.baseDate,
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
