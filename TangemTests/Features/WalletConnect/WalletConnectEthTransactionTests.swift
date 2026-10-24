//
//  WalletConnectEthTransactionTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("WalletConnect Ethereum transaction decoding")
struct WalletConnectEthTransactionTests {
    @Test("A hex chain ID is read as a number")
    func hexChainId() throws {
        let transaction = try decode(chainId: #""0x1237""#)

        #expect(transaction.declaredChainId == 4663)
    }

    @Test("A decimal chain ID is read as a number")
    func decimalChainId() throws {
        let transaction = try decode(chainId: #""4663""#)

        #expect(transaction.declaredChainId == 4663)
    }

    @Test("A numeric chain ID is read as a number")
    func numericChainId() throws {
        let transaction = try decode(chainId: "4663")

        #expect(transaction.declaredChainId == 4663)
    }

    @Test("A missing chain ID stays unknown")
    func missingChainId() throws {
        let transaction = try decode(chainId: nil)

        #expect(transaction.chainId == nil)
        #expect(transaction.declaredChainId == nil)
    }

    @Test("A malformed chain ID never breaks decoding the transaction")
    func malformedChainId() throws {
        let transaction = try decode(chainId: "true")

        #expect(transaction.to == "0x204faca1764b154221e35c0d20abb3c525710498")
        #expect(transaction.declaredChainId == nil)
    }

    @Test("Only non-empty data counts as contract call data", arguments: [
        (nil, false),
        ("0x", false),
        ("", false),
        ("0x3593564c", true),
    ] as [(String?, Bool)])
    func callData(data: String?, carriesCallData: Bool) {
        let transaction = WalletConnectEthTransaction(
            from: "0xfce1fff34c2ca2933efa8bebb35b8f01c0bbc1d7",
            to: "0x204faca1764b154221e35c0d20abb3c525710498",
            value: nil,
            data: data,
            gas: nil,
            gasPrice: nil,
            nonce: nil,
            chainId: nil
        )

        #expect(transaction.carriesCallData == carriesCallData)
    }

    @Test("The chain ID survives re-encoding for the confirmation screen")
    func chainIdSurvivesReencoding() throws {
        let transaction = try decode(chainId: #""0x1237""#)

        let reencoded = try JSONDecoder().decode(WalletConnectEthTransaction.self, from: JSONEncoder().encode(transaction))

        #expect(reencoded.declaredChainId == 4663)
    }
}

// MARK: - Fixtures

private extension WalletConnectEthTransactionTests {
    func decode(chainId: String?) throws -> WalletConnectEthTransaction {
        let chainIdField = chainId.map { #","chainId":\#($0)"# } ?? ""
        let json = """
        {"from":"0xfce1fff34c2ca2933efa8bebb35b8f01c0bbc1d7","to":"0x204faca1764b154221e35c0d20abb3c525710498",\
        "value":"0x2fc06120b792ab1","data":"0x3593564c"\(chainIdField)}
        """

        return try JSONDecoder().decode(WalletConnectEthTransaction.self, from: Data(json.utf8))
    }
}
