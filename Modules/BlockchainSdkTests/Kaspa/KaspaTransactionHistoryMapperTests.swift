//
//  KaspaTransactionHistoryMapperTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
@testable import BlockchainSdk
import Testing

struct KaspaTransactionHistoryMapperTests {
    private let blockchain = Blockchain.kaspa(testnet: false)
    private let walletAddress = "kaspa:wallet"
    private let recipientAddress = "kaspa:recipient"

    /// 1 KAS in, 0.9999 KAS out → fee is 10 000 sompi = 0.0001 KAS.
    @Test
    func outgoingFeeIsConvertedFromSompiToCoin() throws {
        let record = try #require(
            try map(
                inputs: [(walletAddress, 100_000_000)],
                outputs: [(recipientAddress, 99_990_000)]
            )
        )

        #expect(record.isOutgoing)
        #expect(record.fee.amount.type == .coin)
        #expect(record.fee.amount.value == Decimal(string: "0.0001"))
        // Amount and fee must be expressed in the same unit: amount (outputs + fee) is exactly the 1 KAS spent.
        #expect(record.destination == .single(.init(address: .user(recipientAddress), amount: 1)))
        #expect(record.fee.amount.value < 1)
    }

    /// Incoming transfer: the fee was paid by the sender, but it is still reported in coin units.
    @Test
    func incomingFeeIsConvertedFromSompiToCoin() throws {
        let record = try #require(
            try map(
                inputs: [("kaspa:sender", 250_000_000)],
                outputs: [(walletAddress, 200_000_000), ("kaspa:sender", 49_995_000)]
            )
        )

        #expect(!record.isOutgoing)
        #expect(record.fee.amount.value == Decimal(string: "0.00005"))
        #expect(record.destination == .single(.init(address: .user(walletAddress), amount: 2)))
    }

    @Test
    func zeroFeeStaysZero() throws {
        let record = try #require(
            try map(
                inputs: [(walletAddress, 100_000_000)],
                outputs: [(recipientAddress, 100_000_000)]
            )
        )

        #expect(record.fee.amount.value == 0)
    }

    // MARK: - Helpers

    private func map(
        inputs: [(address: String, amount: Int)],
        outputs: [(address: String, amount: Int)]
    ) throws -> TransactionRecord? {
        let inputsJSON = inputs
            .map { #"{ "previousOutpointAddress": "\#($0.address)", "previousOutpointAmount": \#($0.amount) }"# }
            .joined(separator: ",")
        let outputsJSON = outputs
            .map { #"{ "amount": \#($0.amount), "scriptPublicKeyAddress": "\#($0.address)" }"# }
            .joined(separator: ",")

        let json = """
        {
            "transactionId": "kaspa-tx",
            "isAccepted": true,
            "inputs": [\(inputsJSON)],
            "outputs": [\(outputsJSON)]
        }
        """

        let transaction = try JSONDecoder().decode(
            KaspaTransactionHistoryResponse.Transaction.self,
            from: Data(json.utf8)
        )

        return try KaspaTransactionHistoryMapper(blockchain: blockchain)
            .mapToTransactionRecords([transaction], walletAddress: walletAddress, amountType: .coin)
            .first
    }
}
