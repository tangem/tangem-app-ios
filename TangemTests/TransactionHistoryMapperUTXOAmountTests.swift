//
//  TransactionHistoryMapperUTXOAmountTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
@testable import Tangem
@testable import BlockchainSdk

/// A UTXO transaction spends whole inputs, pays the recipient, returns the change and leaves the rest to the
/// miners, so the inputs minus the change is the amount plus the fee.
@Suite("TransactionHistoryMapper UTXO amount")
struct TransactionHistoryMapperUTXOAmountTests {
    @Test("An outgoing UTXO transaction shows what the recipient got, not the fee on top of it")
    func outgoingAmountExcludesTheFee() throws {
        let record = try makeRecord(
            inputs: [(Self.owner, #require(Decimal(stringValue: "0.00200000")))],
            outputs: [
                (Self.recipient, #require(Decimal(stringValue: "0.00100000"))),
                (Self.changeAddress, #require(Decimal(stringValue: "0.00099442"))),
            ]
        )
        let expectedAmount = try #require(Decimal(stringValue: "0.001"))

        #expect(makeSUT().displayedAmountValue(from: record) == expectedAmount)
    }

    @Test("Everything sent to others counts, however many outputs it took")
    func outgoingAmountSumsEveryOutsideOutput() throws {
        let record = try makeRecord(
            inputs: [(Self.owner, #require(Decimal(stringValue: "0.01")))],
            outputs: [
                (Self.recipient, #require(Decimal(stringValue: "0.003"))),
                ("bc1qother", #require(Decimal(stringValue: "0.002"))),
                (Self.owner, #require(Decimal(stringValue: "0.00499"))),
            ]
        )
        let expectedAmount = try #require(Decimal(stringValue: "0.005"))

        #expect(makeSUT().displayedAmountValue(from: record) == expectedAmount)
    }

    /// With nothing leaving the wallet, the fee is all the transaction cost, and it is still worth showing.
    @Test("A transfer between the wallet's own addresses still shows what it cost")
    func transferToItselfShowsTheFee() throws {
        let record = try makeRecord(
            inputs: [(Self.owner, #require(Decimal(stringValue: "0.002")))],
            outputs: [(Self.changeAddress, #require(Decimal(stringValue: "0.00199")))]
        )
        let expectedAmount = try #require(Decimal(stringValue: "0.00001"))

        #expect(makeSUT().displayedAmountValue(from: record) == expectedAmount)
    }

    @Test("An incoming UTXO transaction shows what reached the wallet")
    func incomingAmountIsWhatTheWalletReceived() throws {
        let record = try makeRecord(
            inputs: [("bc1qsender", #require(Decimal(stringValue: "0.01")))],
            outputs: [
                (Self.owner, #require(Decimal(stringValue: "0.004"))),
                ("bc1qsenderchange", #require(Decimal(stringValue: "0.00599"))),
            ],
            isOutgoing: false
        )
        let expectedAmount = try #require(Decimal(stringValue: "0.004"))

        #expect(makeSUT().displayedAmountValue(from: record) == expectedAmount)
    }

    // MARK: - Recents

    @Test("An outgoing UTXO payment suggests its recipient")
    func outgoingPaymentIsSuggested() throws {
        let record = try makeRecord(
            inputs: [(Self.owner, #require(Decimal(stringValue: "0.002")))],
            outputs: [
                (Self.recipient, #require(Decimal(stringValue: "0.001"))),
                (Self.changeAddress, #require(Decimal(stringValue: "0.00099"))),
            ]
        )

        #expect(makeSUT().mapSuggestedRecord(record)?.address == Self.recipient)
    }

    @Test("A UTXO transfer to the wallet's own address is not suggested, even though it cost a fee")
    func transferToItselfIsNotSuggested() throws {
        let record = try makeRecord(
            inputs: [(Self.owner, #require(Decimal(stringValue: "0.002")))],
            outputs: [(Self.changeAddress, #require(Decimal(stringValue: "0.00199")))]
        )

        #expect(makeSUT().mapSuggestedRecord(record) == nil)
    }

    @Test("A zero-value UTXO output is not suggested")
    func zeroValueOutputIsNotSuggested() throws {
        let record = try makeRecord(
            inputs: [(Self.owner, #require(Decimal(stringValue: "0.002")))],
            outputs: [
                (Self.recipient, 0),
                (Self.changeAddress, #require(Decimal(stringValue: "0.00199"))),
            ]
        )

        #expect(makeSUT().mapSuggestedRecord(record) == nil)
    }
}

// MARK: - Helpers

private extension TransactionHistoryMapperUTXOAmountTests {
    static let owner = "bc1qowner"
    static let changeAddress = "bc1qownerchange"
    static let recipient = "bc1qrecipient"

    func makeSUT() -> Tangem.TransactionHistoryMapper {
        Tangem.TransactionHistoryMapper(
            currencySymbol: "BTC",
            blockchain: .bitcoin(testnet: false),
            addressesProvider: StubAddressesProvider(walletAddresses: [Self.owner, Self.changeAddress]),
            showSign: true,
            isToken: false,
            stakingNetwork: nil
        )
    }

    /// Like the UTXO history mapper, reports a lone input or output as `.single`.
    func makeRecord(
        inputs: [(address: String, amount: Decimal)],
        outputs: [(address: String, amount: Decimal)],
        isOutgoing: Bool = true
    ) throws -> TransactionRecord {
        try TransactionRecord(
            hash: "0xHash",
            index: 0,
            source: .from(inputs.map { .init(address: $0.address, amount: $0.amount) }),
            destination: .from(outputs.map { .init(address: .user($0.address), amount: $0.amount) }),
            fee: Fee(Amount(with: .bitcoin(testnet: false), value: #require(Decimal(stringValue: "0.00000558")))),
            status: .confirmed,
            isOutgoing: isOutgoing,
            type: .transfer,
            date: .distantPast,
            tokenTransfers: [],
            nonce: nil
        )
    }
}

// MARK: - Stubs

private struct StubAddressesProvider: WalletModelTransactionHistoryAddressesProvider {
    let walletAddresses: [String]
}
