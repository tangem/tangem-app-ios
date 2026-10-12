//
//  KaspaTransactionHistoryMapperTests.swift
//  BlockchainSdkTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import BlockchainSdk

struct KaspaTransactionHistoryMapperTests {
    private let walletAddress = "kaspa:wallet"

    @Test("Every output of an outgoing transaction carries the amount it actually received")
    func outgoingOutputsCarryTheirOwnAmounts() throws {
        let record = try mapOutgoingTransaction(outputs: [
            ("kaspa:first", 300_000_000),
            ("kaspa:second", 200_000_000),
            (walletAddress, 490_000_000),
        ])

        #expect(record.destination == .multiple([
            .init(address: .user("kaspa:first"), amount: 3),
            .init(address: .user("kaspa:second"), amount: 2),
        ]))
    }

    @Test("The only recipient gets what was sent to it, without the fee")
    func singleRecipientExcludesTheFee() throws {
        let record = try mapOutgoingTransaction(outputs: [
            ("kaspa:recipient", 500_000_000),
            (walletAddress, 490_000_000),
        ])

        #expect(record.destination == .single(.init(address: .user("kaspa:recipient"), amount: 5)))
    }

    @Test("The fee is what the inputs lost beyond the outputs, in KAS rather than sompi")
    func feeIsInKas() throws {
        let record = try mapOutgoingTransaction(outputs: [
            ("kaspa:recipient", 500_000_000),
            (walletAddress, 490_000_000),
        ])

        #expect(record.fee.amount.value == Decimal(string: "0.1"))
    }
}

// MARK: - Helpers

private extension KaspaTransactionHistoryMapperTests {
    /// Spends a single 10 KAS input of the wallet, so whatever the outputs leave unspent is the fee.
    func mapOutgoingTransaction(outputs: [(address: String, amount: Int)]) throws -> TransactionRecord {
        let outputsJSON = outputs
            .map { #"{ "amount": \#($0.amount), "scriptPublicKeyAddress": "\#($0.address)" }"# }
            .joined(separator: ",")

        let json = """
        {
            "transactionId": "tx",
            "isAccepted": true,
            "inputs": [{ "previousOutpointAddress": "\(walletAddress)", "previousOutpointAmount": 1000000000 }],
            "outputs": [\(outputsJSON)]
        }
        """

        let transaction = try JSONDecoder().decode(KaspaTransactionHistoryResponse.Transaction.self, from: Data(json.utf8))
        let mapper = KaspaTransactionHistoryMapper(blockchain: .kaspa(testnet: false))

        let records = try mapper.mapToTransactionRecords([transaction], walletAddress: walletAddress, amountType: .coin)
        try #require(records.count == 1)

        return records[0]
    }
}
