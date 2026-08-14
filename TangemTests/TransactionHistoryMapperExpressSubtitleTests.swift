//
//  TransactionHistoryMapperExpressSubtitleTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
@testable import Tangem
@testable import TangemExpress

@Suite("TransactionHistoryMapper Express row (subtitle & amount)")
struct TransactionHistoryMapperExpressSubtitleTests {
    // MARK: - Type

    @Test("Exchange record maps to the swap type; onramp record maps to the onramp type")
    func expressTypes() {
        #expect(makeSUT().mapTransactionViewModel(swapRecord(isOutgoing: true)).transactionType == .swap)
        #expect(makeSUT().mapTransactionViewModel(onrampRecord(status: .finished, toActualAmount: 1)).transactionType == .onramp)
    }

    // MARK: - Subtitle

    @Test("Swap subtitle shows the counterparty currency with the direction of the viewed leg")
    func swapSubtitleCounterparty() {
        // Viewing the ETH (from) leg → counterparty is the received BTC (to) leg, prefixed `to:`.
        let outgoing = makeSUT().mapTransactionViewModel(swapRecord(isOutgoing: true))
        guard case .express(let model)? = outgoing.display.subtitle else {
            Issue.record("expected an express subtitle for a swap")
            return
        }
        #expect(model.direction == .outgoing)
        #expect(model.symbol == ExpressMergeTestDataFactory.bitcoinToken.currencySymbol)
        #expect(model.owner == nil)
        guard case .token = model.leading else {
            Issue.record("expected a token leading icon")
            return
        }

        // Viewing the BTC (to) leg → counterparty is the sent ETH (from) leg, prefixed `from:`.
        let incoming = makeSUT().mapTransactionViewModel(swapRecord(isOutgoing: false))
        guard case .express(let incomingModel)? = incoming.display.subtitle else {
            Issue.record("expected an express subtitle for a swap")
            return
        }
        #expect(incomingModel.direction == .incoming)
        #expect(incomingModel.symbol == ExpressMergeTestDataFactory.ethereumToken.currencySymbol)
    }

    @Test("Onramp subtitle shows the paid fiat with a `from:` prefix and no owner")
    func onrampSubtitleFiat() {
        let viewModel = makeSUT().mapTransactionViewModel(onrampRecord(status: .waitingForPayment, toActualAmount: nil))
        guard case .express(let model)? = viewModel.display.subtitle else {
            Issue.record("expected an express subtitle for an onramp")
            return
        }
        #expect(model.direction == .incoming)
        #expect(model.symbol == "EUR")
        #expect(model.owner == nil)
        guard case .fiat = model.leading else {
            Issue.record("expected a fiat leading icon")
            return
        }
    }

    @Test("A plain transfer does not produce an express subtitle")
    func plainTransferHasNoExpressSubtitle() {
        let viewModel = makeSUT().mapTransactionViewModel(plainRecord())
        if case .express = viewModel.display.subtitle {
            Issue.record("a non-express row must not use the express subtitle")
        }
    }

    // MARK: - Amount

    @Test("In-progress onramp with an estimated amount shows the `~` prefix and no sign")
    func onrampEstimatedAmountHasTilde() {
        let viewModel = makeSUT().mapTransactionViewModel(onrampRecord(status: .waitingForPayment, toActualAmount: nil))
        #expect(viewModel.amount.value.hasPrefix(AppConstants.tildeSign))
        #expect(!viewModel.amount.value.contains(AppConstants.minusSign))
        #expect(!viewModel.amount.value.contains(AppConstants.plusSign))
    }

    @Test("Finished onramp shows the settled amount without the `~` prefix and without a sign")
    func onrampFinishedAmountHasNoTilde() {
        let viewModel = makeSUT().mapTransactionViewModel(onrampRecord(status: .finished, toActualAmount: 1))
        #expect(!viewModel.amount.value.hasPrefix(AppConstants.tildeSign))
        #expect(!viewModel.amount.value.contains(AppConstants.minusSign))
        #expect(!viewModel.amount.value.contains(AppConstants.plusSign))
    }
}

// MARK: - Helpers

private extension TransactionHistoryMapperExpressSubtitleTests {
    func makeSUT() -> TransactionHistoryMapper {
        TransactionHistoryMapper(
            currencySymbol: "ETH",
            addressesProvider: StubExpressSubtitleAddressesProvider(walletAddresses: ["0xSource"]),
            showSign: true,
            isToken: false
        )
    }

    func baseRecord(isOutgoing: Bool, extraInfo: TransactionHistoryExpressExtraInfo?) -> TransactionRecord {
        let record = TransactionRecord(
            hash: "hash",
            index: 0,
            source: .single(.init(address: "0xSource", amount: 1)),
            destination: .single(.init(address: .user("0xDestination"), amount: 1)),
            fee: ExpressMergeTestDataFactory.ethereumToken.zeroFee,
            status: .confirmed,
            isOutgoing: isOutgoing,
            type: .transfer,
            date: ExpressMergeTestDataFactory.baseDate,
            tokenTransfers: [],
            nonce: nil
        )
        return extraInfo.map { record.withExpressExtraInfo($0) } ?? record
    }

    func plainRecord() -> TransactionRecord {
        baseRecord(isOutgoing: true, extraInfo: nil)
    }

    func swapRecord(isOutgoing: Bool) -> TransactionRecord {
        let fromCurrency = ExpressMergeTestDataFactory.matchingCurrency(for: ExpressMergeTestDataFactory.ethereumToken)
        let toCurrency = ExpressMergeTestDataFactory.matchingCurrency(for: ExpressMergeTestDataFactory.bitcoinToken)

        let info = ExchangeTransactionInfo(
            transaction: ExpressMergeTestDataFactory.exchangeTransaction(
                txId: "tx",
                status: .sending,
                fromAddress: "0xFrom",
                payInAddress: "0xIn",
                payInHash: nil,
                payOutAddress: "0xOut",
                payOutHash: nil,
                fromCurrency: fromCurrency,
                fromAmount: 1,
                fromActualAmount: nil,
                toCurrency: toCurrency,
                toAmount: 1,
                toActualAmount: nil,
                refund: nil,
                createdAt: ExpressMergeTestDataFactory.baseDate,
                updatedAt: ExpressMergeTestDataFactory.baseDate
            ),
            provider: nil,
            cryptoCurrencies: [
                fromCurrency: ExpressMergeTestDataFactory.ethereumToken,
                toCurrency: ExpressMergeTestDataFactory.bitcoinToken,
            ]
        )
        return baseRecord(isOutgoing: isOutgoing, extraInfo: .exchange(info))
    }

    func onrampRecord(status: OnrampTransactionStatus, toActualAmount: Decimal?) -> TransactionRecord {
        let info = OnrampTransactionInfo(
            transaction: ExpressMergeTestDataFactory.onrampTransaction(
                txId: "tx",
                status: status,
                payOutAddress: "0xOut",
                payOutHash: nil,
                toCurrency: ExpressMergeTestDataFactory.matchingCurrency(for: ExpressMergeTestDataFactory.ethereumToken),
                toAmount: 1,
                toActualAmount: toActualAmount,
                createdAt: ExpressMergeTestDataFactory.baseDate,
                updatedAt: ExpressMergeTestDataFactory.baseDate
            ),
            provider: nil,
            fiatCurrency: nil,
            cryptoCurrencies: [:]
        )
        return baseRecord(isOutgoing: false, extraInfo: .onramp(info))
    }
}

// MARK: - Stubs

private struct StubExpressSubtitleAddressesProvider: WalletModelTransactionHistoryAddressesProvider {
    let walletAddresses: [String]
}
