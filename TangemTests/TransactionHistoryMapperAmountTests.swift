//
//  TransactionHistoryMapperAmountTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import BlockchainSdk
@testable import Tangem

@Suite("TransactionHistoryMapper amount sign policy")
struct TransactionHistoryMapperAmountTests {
    @Test("Failed tx renders the redesign `value` unsigned (the strikethrough conveys failure)")
    func failedValueIsUnsigned() {
        let viewModel = makeSUT().mapTransactionViewModel(makeRecord(status: .failed, isOutgoing: true))

        #expect(!viewModel.amount.value.hasPrefix(AppConstants.minusSign))
        #expect(!viewModel.amount.value.hasPrefix(AppConstants.plusSign))
    }

    @Test("Confirmed outgoing tx keeps the leading sign on the redesign `value`")
    func confirmedOutgoingValueIsSigned() {
        let viewModel = makeSUT().mapTransactionViewModel(makeRecord(status: .confirmed, isOutgoing: true))

        #expect(viewModel.amount.value.hasPrefix(AppConstants.minusSign))
    }

    @Test("Failed tx keeps the sign on the legacy `amount` string (redesign-vs-legacy divergence)")
    func failedLegacyAmountKeepsSign() {
        let viewModel = makeSUT().mapTransactionViewModel(makeRecord(status: .failed, isOutgoing: true))

        #expect(viewModel.amount.amount.hasPrefix(AppConstants.minusSign))
    }

    @Test("A staking record whose self destination carries a zeroed amount nets to the gross source amount with the outgoing minus, not to zero")
    func zeroedSelfDestinationNetsToGrossAmount() {
        let record = TransactionRecord(
            hash: "hash",
            index: 0,
            source: .single(.init(address: "0xSource", amount: 2)),
            destination: .single(.init(address: .user("0xSource"), amount: 0)),
            fee: Fee(Amount(type: .coin, currencySymbol: "ETH", value: 0, decimals: 18)),
            status: .confirmed,
            isOutgoing: true,
            type: .staking(type: .stake, target: nil),
            date: Date()
        )

        let viewModel = makeSUT().mapTransactionViewModel(record)

        #expect(viewModel.amount.amount == AppConstants.minusSign + BalanceFormatter().formatCryptoBalance(2, currencyCode: "ETH"))
    }
}

// MARK: - Helpers

private extension TransactionHistoryMapperAmountTests {
    func makeSUT() -> Tangem.TransactionHistoryMapper {
        Tangem.TransactionHistoryMapper(
            currencySymbol: "ETH",
            addressesProvider: StubTransactionHistoryAddressesProvider(walletAddresses: ["0xSource"]),
            showSign: true,
            isToken: false
        )
    }

    func makeRecord(status: TransactionRecord.TransactionStatus, isOutgoing: Bool) -> TransactionRecord {
        TransactionRecord(
            hash: "hash",
            index: 0,
            source: .single(.init(address: "0xSource", amount: 1)),
            destination: .single(.init(address: .user("0xDestination"), amount: 1)),
            fee: Fee(Amount(type: .coin, currencySymbol: "ETH", value: 0, decimals: 18)),
            status: status,
            isOutgoing: isOutgoing,
            type: .transfer,
            date: Date(),
            tokenTransfers: [],
            nonce: nil
        )
    }
}

// MARK: - Stubs

private struct StubTransactionHistoryAddressesProvider: WalletModelTransactionHistoryAddressesProvider {
    let walletAddresses: [String]
}
