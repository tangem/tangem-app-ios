//
//  KaspaTransactionHistoryTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import BlockchainSdk

struct KaspaTransactionHistoryTests {
    private func decode(_ json: String) throws -> KaspaTransactionHistoryResponse.Transaction {
        let decoder = JSONDecoder()
        return try decoder.decode(KaspaTransactionHistoryResponse.Transaction.self, from: Data(json.utf8))
    }

    @Test
    func validInputsAndOutputs() throws {
        let json = """
        {
            "inputs": [
                { "previousOutpointAddress": "kaspa:abc", "previousOutpointAmount": 123 }
            ],
            "outputs": [
                { "amount": 456, "scriptPublicKeyAddress": "kaspa:def" }
            ]
        }
        """
        let transaction = try decode(json)
        #expect(transaction.inputs.count == 1)
        #expect(transaction.inputs[0].previousOutpointAmount == 123)
        #expect(transaction.outputs.count == 1)
        #expect(transaction.outputs[0].amount == 456)
    }

    @Test
    func nullInputsAndOutputs() throws {
        let json = """
        {
            "inputs": null,
            "outputs": null
        }
        """
        let transaction = try decode(json)
        #expect(transaction.inputs.isEmpty)
        #expect(transaction.outputs.isEmpty)
    }

    @Test
    func missingInputsAndOutputs() throws {
        let json = """
        {
            "transactionId": "noio"
        }
        """
        let transaction = try decode(json)
        #expect(transaction.inputs.isEmpty)
        #expect(transaction.outputs.isEmpty)
    }

    @Test
    func invalidElementsInInputsAndOutputs() throws {
        let json = """
        {
            "inputs": [
                { "previousOutpointAddress": "kaspa:good", "previousOutpointAmount": 999 },
                { "previousOutpointAmount": "oops" }
            ],
            "outputs": [
                { "amount": "bad", "scriptPublicKeyAddress": "kaspa:bad" },
                { "amount": 888 }
            ]
        }
        """
        let transaction = try decode(json)
        #expect(transaction.inputs.count == 1)
        #expect(transaction.inputs[0].previousOutpointAddress == "kaspa:good")
        #expect(transaction.outputs.count == 1)
        #expect(transaction.outputs[0].amount == 888)
    }
}
