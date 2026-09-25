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
        let record = makeRecord(
            inputs: [(Self.owner, dec("0.00200000"))],
            outputs: [(Self.recipient, dec("0.00100000")), (Self.changeAddress, dec("0.00099442"))]
        )

        #expect(makeSUT().transferAmountValue(from: record) == dec("0.001"))
    }

    @Test("Everything sent to others counts, however many outputs it took")
    func outgoingAmountSumsEveryOutsideOutput() throws {
        let record = makeRecord(
            inputs: [(Self.owner, dec("0.01"))],
            outputs: [(Self.recipient, dec("0.003")), ("bc1qother", dec("0.002")), (Self.owner, dec("0.00499"))]
        )

        #expect(makeSUT().transferAmountValue(from: record) == dec("0.005"))
    }

    /// With nothing leaving the wallet, the fee is all the transaction cost, and it is still worth showing.
    @Test("A transfer between the wallet's own addresses still shows what it cost")
    func transferToItselfShowsTheFee() throws {
        let record = makeRecord(
            inputs: [(Self.owner, dec("0.002"))],
            outputs: [(Self.changeAddress, dec("0.00199"))]
        )

        #expect(makeSUT().transferAmountValue(from: record) == dec("0.00001"))
    }

    @Test("An incoming UTXO transaction shows what reached the wallet")
    func incomingAmountIsWhatTheWalletReceived() throws {
        let record = makeRecord(
            inputs: [("bc1qsender", dec("0.01"))],
            outputs: [(Self.owner, dec("0.004")), ("bc1qsenderchange", dec("0.00599"))],
            isOutgoing: false
        )

        #expect(makeSUT().transferAmountValue(from: record) == dec("0.004"))
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

    func makeRecord(
        inputs: [(address: String, amount: Decimal)],
        outputs: [(address: String, amount: Decimal)],
        isOutgoing: Bool = true
    ) -> TransactionRecord {
        TransactionRecord(
            hash: "0xHash",
            index: 0,
            source: .multiple(inputs.map { .init(address: $0.address, amount: $0.amount) }),
            destination: .multiple(outputs.map { .init(address: .user($0.address), amount: $0.amount) }),
            fee: Fee(Amount(with: .bitcoin(testnet: false), value: dec("0.00000558"))),
            status: .confirmed,
            isOutgoing: isOutgoing,
            type: .transfer,
            date: .distantPast,
            tokenTransfers: [],
            nonce: nil
        )
    }

    func dec(_ string: String) -> Decimal {
        Decimal(stringValue: string)!
    }
}

// MARK: - Stubs

private struct StubAddressesProvider: WalletModelTransactionHistoryAddressesProvider {
    let walletAddresses: [String]
}
