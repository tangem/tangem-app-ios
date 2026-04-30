//
//  MantleTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
@testable import BlockchainSdk

struct MantleTransactionTests {
    private let blockchain = Blockchain.mantle(testnet: false)

    @Test
    func decodeEncodedForSend() throws {
        let testCases: [Decimal] = [
            try #require(Decimal(stringValue: "29.618123086712134")),
            try #require(Decimal(stringValue: "0.000000000003194")),
            try #require(Decimal(stringValue: "84.329847293749302")),
            try #require(Decimal(stringValue: "19.287394872934987")),
            try #require(Decimal(stringValue: "73.928374982374892")),
            try #require(Decimal(stringValue: "1.847392874932748")),
            try #require(Decimal(stringValue: "47.832984723984723")),
            try #require(Decimal(stringValue: "0.0000000001234567")),
            try #require(Decimal(stringValue: "56.392847293847298")),
        ]

        try testCases.forEach { decimal in
            let amount = Amount(with: blockchain, type: .coin, value: decimal)

            let encodedForSend = try #require(amount.encodedForSend)
            let decodedValue = EthereumUtils.parseEthereumDecimal(encodedForSend, decimalsCount: blockchain.decimalCount)

            #expect(decodedValue == decimal)
        }
    }
}
