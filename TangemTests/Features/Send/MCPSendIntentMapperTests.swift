//
//  MCPSendIntentMapperTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

struct MCPSendIntentMapperTests {
    @Test
    func mapsCreatedIntent() throws {
        let intent = try map(Self.makeJSON())

        #expect(
            intent == SendMCPIntent(
                id: "3f7c2a1e-9b4d-4c6a-8e21-5d0f7a9b1c33",
                networkID: "polygon-pos",
                tokenID: "tether",
                fromAddress: "0xd8da6bf26964af9d7eed9e03e53415d37aa96045",
                toAddress: "0x1111111111111111111111111111111111111111",
                amount: Decimal(string: "12.5", locale: Locale(identifier: "en_US_POSIX"))!,
                memo: "12345",
                isCompleted: false,
                agentID: "https://claude.ai/oauth/claude-code-client-metadata"
            )
        )
    }

    @Test(arguments: [
        CompletionTestCase(status: "CREATED", txHash: nil, isCompleted: false),
        CompletionTestCase(status: "COMPLETED", txHash: nil, isCompleted: true),
        CompletionTestCase(status: "CREATED", txHash: "0xabc", isCompleted: true),
    ])
    private func treatsReportedOrCompletedIntentAsCompleted(testCase: CompletionTestCase) throws {
        let intent = try map(Self.makeJSON(status: testCase.status, txHash: testCase.txHash))

        #expect(intent.isCompleted == testCase.isCompleted)
    }

    @Test
    func rejectsUnsupportedType() throws {
        let error = try #require(throws: SendMCPIntentError.self) {
            try map(Self.makeJSON(type: "SWAP"))
        }

        guard case .unsupportedType("SWAP") = error else {
            Issue.record("Expected .unsupportedType, got \(error)")
            return
        }
    }

    @Test(arguments: [
        TypeAndStatusTestCase(type: "send", status: "created"),
        TypeAndStatusTestCase(type: "Send", status: "Created"),
    ])
    private func acceptsTypeAndStatusInAnyCase(testCase: TypeAndStatusTestCase) throws {
        let intent = try map(Self.makeJSON(type: testCase.type, status: testCase.status))

        #expect(!intent.isCompleted)
    }

    @Test(arguments: ["EXPIRED", "FAILED", ""])
    func treatsUnknownStatusAsCompleted(status: String) throws {
        let intent = try map(Self.makeJSON(status: status))

        #expect(intent.isCompleted)
    }

    @Test(arguments: ["0.000000000000000001", "123456789012345678901234567890", "0.5"])
    func keepsAmountExactly(amount: String) throws {
        let intent = try map(Self.makeJSON(amount: amount))

        #expect(intent.amount == Decimal(string: amount, locale: Locale(identifier: "en_US_POSIX")))
    }

    @Test
    func keepsMissingMemoEmpty() throws {
        let intent = try map(Self.makeJSON(memo: nil))

        #expect(intent.memo == nil)
    }

    @Test
    func rejectsIntentWithoutAgent() {
        #expect(throws: DecodingError.self) {
            try map(Self.makeJSON(clientId: nil))
        }
    }

    @Test(arguments: ["abc", "12,5", "1,000.50", "0", "-1", "", ".5", "1.", "1e5", " 1", "1 ", "+1", "0x10", "NaN"])
    func rejectsInvalidAmount(amount: String) throws {
        let error = try #require(throws: SendMCPIntentError.self) {
            try map(Self.makeJSON(amount: amount))
        }

        guard case .invalidAmount(amount) = error else {
            Issue.record("Expected .invalidAmount, got \(error)")
            return
        }
    }

    private func map(_ json: String) throws -> SendMCPIntent {
        let response = try JSONDecoder().decode(FetchMCPSendIntentDTO.Response.self, from: Data(json.utf8))
        return try SendMCPIntentMapper.mapToDomainIntent(response)
    }

    private static func makeJSON(
        type: String = "SEND",
        status: String = "CREATED",
        amount: String = "12.5",
        memo: String? = "12345",
        txHash: String? = nil,
        clientId: String? = "https://claude.ai/oauth/claude-code-client-metadata"
    ) -> String {
        let txHashField = txHash.map { #""txHash": "\#($0)","# } ?? ""
        let memoValue = memo.map { #""\#($0)""# } ?? "null"
        let clientIdValue = clientId.map { #""\#($0)""# } ?? "null"

        return """
        {
          "intentId": "3f7c2a1e-9b4d-4c6a-8e21-5d0f7a9b1c33",
          "type": "\(type)",
          "status": "\(status)",
          "networkId": "polygon-pos",
          "fromAddress": "0xd8da6bf26964af9d7eed9e03e53415d37aa96045",
          "toAddress": "0x1111111111111111111111111111111111111111",
          "tokenId": "tether",
          "amount": "\(amount)",
          "memo": \(memoValue),
          "comment": "Some comment",
          \(txHashField)
          "createdAt": "2026-09-17T13:05:12Z",
          "sessionId": "87f700a5-8196-4ab9-899d-81409131d33b",
          "clientId": \(clientIdValue)
        }
        """
    }
}

// MARK: - Test cases

extension MCPSendIntentMapperTests {
    private struct CompletionTestCase {
        let status: String
        let txHash: String?
        let isCompleted: Bool
    }

    private struct TypeAndStatusTestCase {
        let type: String
        let status: String
    }
}
