//
//  JointOperationsHistoryMapperTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("Tests for reading the joint operations history off the endpoint")
struct JointOperationsHistoryMapperTests {
    private let mapper = JointAccountsNetworkMapper()

    @Test("The first page is read with its items and the cursors to go on from")
    func firstPageIsRead() throws {
        let response: JointAccountsDTO.Response.OperationsHistory = try Self.decode(
            Constants.pageJSON(items: [Constants.operationJSON()])
        )

        let page = mapper.mapToHistoryPage(from: response)

        #expect(page.nextCursor == Constants.endCursor)
        #expect(page.startDeltaCursor == Constants.startDeltaCursor)
        #expect(page.hasMore)

        let item = try #require(page.items.singleElement)
        #expect(item.operation.id == Constants.operationId)
        #expect(item.operation.chainId == 8453)
        #expect(item.operation.status == .executed)
        #expect(item.operation.txHash == Constants.txHash)
        #expect(item.operation.initiator == Constants.initiator)
        #expect(item.operation.safeTransaction.nonce == 7)
        #expect(item.operation.signatures.map(\.state) == [.signed, .signed])
        #expect(item.cryptoAccountId == Constants.cryptoAccountId)
        #expect(item.safeAddress == Constants.safeAddress)
        #expect(item.threshold == 2)
        #expect(item.createdAt == Constants.createdAt)
        #expect(item.finishedAt == Constants.finishedAt)
        #expect(item.cancelReason == nil)
    }

    @Test("An empty history is a page with nothing to go on from")
    func emptyHistoryIsRead() throws {
        let response: JointAccountsDTO.Response.OperationsHistory = try Self.decode(
            Constants.pageJSON(items: [], endCursor: nil, startDeltaCursor: nil, hasMore: false)
        )

        let page = mapper.mapToHistoryPage(from: response)

        #expect(page.items.isEmpty)
        #expect(page.nextCursor == nil)
        #expect(page.startDeltaCursor == nil)
        #expect(!page.hasMore)
    }

    @Test("The single operation answer is the very item the history lists")
    func singleOperationIsRead() throws {
        let response: JointAccountsDTO.Response.HistoryOperation = try Self.decode(Constants.operationJSON())

        let item = try mapper.mapToHistoryItem(from: response)

        #expect(item.operation.id == Constants.operationId)
        #expect(item.operation.txHash == Constants.txHash)
        #expect(item.finishedAt == Constants.finishedAt)
    }

    @Test("A delta page continues from its own cursor and never starts a delta")
    func deltaPageIsRead() throws {
        let response: JointAccountsDTO.Response.OperationsHistoryDelta = try Self.decode(
            Constants.deltaPageJSON(items: [Constants.operationJSON()], startCursor: "delta-cursor", hasMore: false)
        )

        let page = mapper.mapToHistoryPage(from: response)

        #expect(page.items.map(\.operation.id) == [Constants.operationId])
        #expect(page.nextCursor == "delta-cursor")
        #expect(page.startDeltaCursor == nil)
        #expect(!page.hasMore)
    }

    @Test("The listing goes on reporting an operation without a hash")
    func listingOperationHasNoHash() throws {
        let response: JointAccountsDTO.Response.Operation = try Self.decode(Constants.operationJSON())

        #expect(try mapper.mapToOperation(from: response).txHash == nil)
    }

    @Test("A stage this version has never heard of is read as unknown")
    func unfamiliarStatusIsRead() throws {
        let response: JointAccountsDTO.Response.HistoryOperation = try Self.decode(
            Constants.operationJSON(status: "settling", txHash: nil, finishedAt: nil)
        )

        #expect(try mapper.mapToHistoryItem(from: response).operation.status == .unknown)
    }

    @Test(
        "A cancel reason is read by name, and one this version has never heard of is dropped",
        arguments: [
            ("initiator", JointOperationCancelReason.initiator),
            ("threshold", .threshold),
            ("weather", nil),
        ] as [(String, JointOperationCancelReason?)]
    )
    func cancelReasonIsRead(rawValue: String, expected: JointOperationCancelReason?) throws {
        let response: JointAccountsDTO.Response.HistoryOperation = try Self.decode(
            Constants.operationJSON(status: "cancelled", txHash: nil, cancelReason: rawValue)
        )

        let item = try mapper.mapToHistoryItem(from: response)

        #expect(item.operation.status == .cancelled)
        #expect(item.cancelReason == expected)
    }

    @Test("An item the mapper cannot read is skipped, and the page keeps the others")
    func malformedItemIsSkipped() throws {
        let response: JointAccountsDTO.Response.OperationsHistory = try Self.decode(
            Constants.pageJSON(items: [
                Constants.operationJSON(id: "malformed", baseGas: "lots"),
                Constants.operationJSON(id: "readable"),
            ])
        )

        #expect(mapper.mapToHistoryPage(from: response).items.map(\.operation.id) == ["readable"])
    }

    @Test("An item the decoder cannot read is skipped, and the page keeps the others")
    func undecodableItemIsSkipped() throws {
        let undecodable = Constants.operationJSON(id: "undecodable").replacingOccurrences(of: "\"cryptoAccountId\"", with: "\"accountId\"")
        let response: JointAccountsDTO.Response.OperationsHistory = try Self.decode(
            Constants.pageJSON(items: [undecodable, Constants.operationJSON(id: "readable")])
        )

        #expect(mapper.mapToHistoryPage(from: response).items.map(\.operation.id) == ["readable"])
    }

    @Test("An operation that has not reached the chain, or never will, has no hash", arguments: ["pending", "cancelled"])
    func unfinishedOperationHasNoHash(status: String) throws {
        let response: JointAccountsDTO.Response.HistoryOperation = try Self.decode(
            Constants.operationJSON(status: status, txHash: nil, finishedAt: nil)
        )

        let item = try mapper.mapToHistoryItem(from: response)

        #expect(item.operation.txHash == nil)
        #expect(item.finishedAt == nil)
    }

    @Test("The hash and the Safe address are read lower-cased, however the endpoint spells them")
    func hashAndAddressAreLowercased() throws {
        let response: JointAccountsDTO.Response.HistoryOperation = try Self.decode(
            Constants.operationJSON(txHash: Constants.txHash.uppercased(), safeAddress: Constants.safeAddress.uppercased())
        )

        let item = try mapper.mapToHistoryItem(from: response)

        #expect(item.operation.txHash == Constants.txHash)
        #expect(item.safeAddress == Constants.safeAddress)
    }

    @Test("A date is read with fractional seconds and without them", arguments: ["2026-09-08T09:20:37.000Z", "2026-09-08T09:20:37Z"])
    func dateIsReadEitherWay(createdAt: String) throws {
        let response: JointAccountsDTO.Response.HistoryOperation = try Self.decode(Constants.operationJSON(createdAt: createdAt))

        #expect(try mapper.mapToHistoryItem(from: response).createdAt == Constants.createdAt)
    }

    @Test("A date that cannot be read refuses the item, which a page then skips")
    func unreadableDateRefusesTheItem() throws {
        let item: JointAccountsDTO.Response.HistoryOperation = try Self.decode(Constants.operationJSON(createdAt: "yesterday"))
        let page: JointAccountsDTO.Response.OperationsHistory = try Self.decode(
            Constants.pageJSON(items: [Constants.operationJSON(createdAt: "yesterday")])
        )

        #expect(throws: JointAccountsNetworkMapperError.malformedOperation(field: "createdAt")) {
            try mapper.mapToHistoryItem(from: item)
        }
        #expect(mapper.mapToHistoryPage(from: page).items.isEmpty)
    }

    @Test("An operation stored before the hash was known decodes without it")
    func storedOperationWithoutHashDecodes() throws {
        let operation = JointAccountCompositionFixture.coinTransfer()
        let stored = try JSONEncoder().encode(operation)
        let storedFields = try #require(try JSONSerialization.jsonObject(with: stored) as? [String: Any])

        #expect(storedFields["txHash"] == nil)
        #expect(try JSONDecoder().decode(JointAccountOperation.self, from: stored) == operation)
    }
}

// MARK: - Fixtures

private extension JointOperationsHistoryMapperTests {
    enum Constants {
        static let operationId = "0b4f2c1e-6a3d-4f5b-9c8e-1d2a3b4c5d6e"
        static let txHash = "0x4e3a3754410177e6937ef1f84bba68ea139e8d1a2258c5f85db9f1cd715a1bdd"
        static let safeAddress = "0x8f3ac21b7e5f4552091a69125d5dfcb7b8c26590"
        static let initiator = "0x7e5f4552091a69125d5dfcb7b8c2659029395bdf"
        static let cryptoAccountId = "A7B3C9D2E4F60718293A4B5C6D7E8F9A0B1C2D3E4F5061728394A5B6C7D8E9F0"
        static let endCursor = "eyJjcmVhdGVkQXQiOiIyMDI2LTA5LTA4VDA5OjIwOjM3LjAwMFoifQ"
        static let startDeltaCursor = "eyJ1cGRhdGVkQXQiOiIyMDI2LTA5LTA4VDA5OjI0OjAyLjAwMFoifQ"
        static let createdAt = Date(timeIntervalSince1970: 1_788_859_237)
        static let finishedAt = Date(timeIntervalSince1970: 1_788_859_442)

        static func operationJSON(
            id: String = Constants.operationId,
            status: String = "executed",
            txHash: String? = Constants.txHash,
            finishedAt: String? = "2026-09-08T09:24:02.000Z",
            cancelReason: String? = nil,
            createdAt: String = "2026-09-08T09:20:37.000Z",
            safeAddress: String = Constants.safeAddress,
            baseGas: String = "30000"
        ) -> String {
            """
            {
              "operationId": "\(id)", "chainId": 8453, "status": "\(status)",
              "safeTx": {
                "to": "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913", "value": "0",
                "data": "0xa9059cbb0000000000000000000000002b5ad9c1e7f40638b2c1a9d3e5f70241c6b8a91c00000000000000000000000000000000000000000000000000000000000f4240",
                "operation": 0, "safeTxGas": "65000", "baseGas": "\(baseGas)", "gasPrice": "2000000000",
                "gasToken": "0x0000000000000000000000000000000000000000",
                "refundReceiver": "\(initiator)", "nonce": "7"
              },
              "initiator": "\(initiator)", "threshold": 2,
              "votes": [
                { "address": "\(initiator)", "vote": "approve", "signature": null, "votedAt": "2026-09-08T09:20:37.000Z" },
                { "address": "0x2b5ad5c4795c026514f8317c7a215e218dccd6cf", "vote": "approve", "signature": null, "votedAt": "2026-09-08T09:23:51.000Z" }
              ],
              "createdAt": "\(createdAt)",
              "cryptoAccountId": "\(cryptoAccountId)", "safeAddress": "\(safeAddress)",
              "txHash": \(jsonValue(txHash)), "finishedAt": \(jsonValue(finishedAt)), "cancelReason": \(jsonValue(cancelReason))
            }
            """
        }

        static func pageJSON(
            items: [String],
            endCursor: String? = Constants.endCursor,
            startDeltaCursor: String? = Constants.startDeltaCursor,
            hasMore: Bool = true
        ) -> String {
            """
            {
              "items": [\(items.joined(separator: ","))],
              "pagination": { "endCursor": \(jsonValue(endCursor)), "startDeltaCursor": \(jsonValue(startDeltaCursor)), "hasMore": \(hasMore) }
            }
            """
        }

        static func deltaPageJSON(items: [String], startCursor: String?, hasMore: Bool) -> String {
            """
            {
              "items": [\(items.joined(separator: ","))],
              "pagination": { "startCursor": \(jsonValue(startCursor)), "hasMore": \(hasMore) }
            }
            """
        }

        private static func jsonValue(_ value: String?) -> String {
            value.map { "\"\($0)\"" } ?? "null"
        }
    }

    static func decode<T: Decodable>(_ json: String) throws -> T {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        return try decoder.decode(T.self, from: Data(json.utf8))
    }
}
