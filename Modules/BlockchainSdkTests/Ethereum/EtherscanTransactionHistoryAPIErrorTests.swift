//
//  EtherscanTransactionHistoryAPIErrorTests.swift
//  BlockchainSdkTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
@testable import BlockchainSdk
import Testing

struct EtherscanTransactionHistoryAPIErrorTests {
    private let mapper = EtherscanTransactionHistoryMapper(blockchain: .polygon(testnet: false))
    private let walletAddress = "0x9b486974723832742c87566136bd7276a6d13106"

    @Test(
        "A reached rate limit is recognized whatever the wording and case",
        arguments: [
            "Max rate limit reached",
            "Max rate limit reached, please use API Key for higher rate limit",
            "Max calls per sec rate limit reached (5/sec)",
            "MAX CALLS PER SEC RATE LIMIT REACHED (5/SEC)",
        ]
    )
    func rateLimitIsRecognized(description: String) {
        #expect(throws: EtherscanAPIError.maxRateLimitReached) {
            try mapRecords(failedWith: description)
        }
    }

    @Test("An empty transaction list is the end of the history, not a rate limit")
    func emptyResultIsEndOfHistory() {
        // This is what the API answers once the pages run out
        let response = EtherscanTransactionHistoryResult(status: "0", message: "No transactions found", result: .transactions([]))

        #expect(throws: EtherscanAPIError.endOfTransactionHistoryReached) {
            try mapRecords(from: response)
        }
    }

    @Test("An unrelated failure description stays unknown")
    func unrelatedDescriptionIsUnknown() {
        #expect(throws: EtherscanAPIError.unknown) {
            try mapRecords(failedWith: "Invalid address format")
        }
    }

    @Test("A successful response with no transactions is not a failure")
    func successfulEmptyResponseIsNotAFailure() throws {
        // Only a failed status ends the history; a successful empty page is just a page with nothing to show
        let response = EtherscanTransactionHistoryResult(status: "1", message: nil, result: .transactions([]))

        let records = try mapRecords(from: response)

        #expect(records.isEmpty)
    }
}

// MARK: - Helpers

private extension EtherscanTransactionHistoryAPIErrorTests {
    func mapRecords(failedWith description: String) throws -> [TransactionRecord] {
        try mapRecords(from: EtherscanTransactionHistoryResult(status: "0", message: "NOTOK", result: .description(description)))
    }

    func mapRecords(from response: EtherscanTransactionHistoryResult) throws -> [TransactionRecord] {
        try mapper.mapToTransactionRecords(response, walletAddress: walletAddress, amountType: .coin)
    }
}
