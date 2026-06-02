//
//  TronTransactionHistoryMapperTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
@testable import BlockchainSdk
import Testing

struct TronTransactionHistoryMapperTests {
    private let blockchain = Blockchain.tron(testnet: false)
    private let walletAddress = "TJRyWwFs9wTFGZg3JbrVriFbNfCug5tDeC"
    private let otherAddress = "TQrY8tryqsYVCYS3MFbtffiPp2ccyn4STm"

    // MARK: - Baseline (dedicated `fromAddress` / `toAddress` fields)

    @Test
    func mapsCoinTransferUsingFromAndToAddresses() throws {
        let mapper = TronTransactionHistoryMapper(blockchain: blockchain)
        let response = try decodeResponse(
            transaction: transactionJSON(fromAddress: walletAddress, toAddress: otherAddress)
        )

        let records = try mapper.mapToTransactionRecords(response, walletAddress: walletAddress, amountType: .coin)

        #expect(records.count == 1)
        #expect(records[0].type == .transfer)
        #expect(records[0].isOutgoing)
        #expect(records[0].source == .single(.init(address: walletAddress, amount: 1)))
        #expect(records[0].destination == .single(.init(address: .user(otherAddress), amount: 1)))
    }

    // MARK: - Fallback to `vin` / `vout` (NowNodes contract change, [REDACTED_INFO])

    @Test
    func mapsOutgoingCoinTransferFallingBackToVinVoutAddresses() throws {
        let mapper = TronTransactionHistoryMapper(blockchain: blockchain)
        let response = try decodeResponse(
            transaction: transactionJSON(vinAddress: walletAddress, voutAddress: otherAddress)
        )

        let records = try mapper.mapToTransactionRecords(response, walletAddress: walletAddress, amountType: .coin)

        #expect(records.count == 1)
        #expect(records[0].isOutgoing)
        #expect(records[0].source == .single(.init(address: walletAddress, amount: 1)))
        #expect(records[0].destination == .single(.init(address: .user(otherAddress), amount: 1)))
    }

    @Test
    func mapsIncomingCoinTransferFallingBackToVinVoutAddresses() throws {
        let mapper = TronTransactionHistoryMapper(blockchain: blockchain)
        let response = try decodeResponse(
            transaction: transactionJSON(vinAddress: otherAddress, voutAddress: walletAddress)
        )

        let records = try mapper.mapToTransactionRecords(response, walletAddress: walletAddress, amountType: .coin)

        #expect(records.count == 1)
        #expect(!records[0].isOutgoing)
        #expect(records[0].source == .single(.init(address: otherAddress, amount: 1)))
        #expect(records[0].destination == .single(.init(address: .user(walletAddress), amount: 1)))
    }

    @Test
    func prefersDedicatedAddressFieldsOverVinVout() throws {
        let mapper = TronTransactionHistoryMapper(blockchain: blockchain)
        let response = try decodeResponse(
            transaction: transactionJSON(
                fromAddress: walletAddress,
                toAddress: otherAddress,
                vinAddress: "TWrongVinAddress0000000000000000000",
                voutAddress: "TWrongVoutAddress000000000000000000"
            )
        )

        let records = try mapper.mapToTransactionRecords(response, walletAddress: walletAddress, amountType: .coin)

        #expect(records.count == 1)
        #expect(records[0].source == .single(.init(address: walletAddress, amount: 1)))
        #expect(records[0].destination == .single(.init(address: .user(otherAddress), amount: 1)))
    }

    @Test
    func skipsCoinTransferWhenNeitherAddressNorVinVoutPresent() throws {
        let mapper = TronTransactionHistoryMapper(blockchain: blockchain)
        let response = try decodeResponse(transaction: transactionJSON())

        let records = try mapper.mapToTransactionRecords(response, walletAddress: walletAddress, amountType: .coin)

        #expect(records.isEmpty)
    }

    // MARK: - Helpers

    private func transactionJSON(
        fromAddress: String? = nil,
        toAddress: String? = nil,
        vinAddress: String? = nil,
        voutAddress: String? = nil
    ) -> String {
        var fields: [String] = [
            "\"txid\": \"abc123deadbeef\"",
            "\"contract_type\": 1",
            "\"blockHeight\": 1",
            "\"confirmations\": 1",
            "\"blockTime\": 1700000000",
            "\"value\": \"1000000\"",
            "\"fees\": \"0\"",
            "\"tronTXReceipt\": { \"status\": 1 }",
        ]

        if let fromAddress {
            fields.append("\"fromAddress\": \"\(fromAddress)\"")
        }
        if let toAddress {
            fields.append("\"toAddress\": \"\(toAddress)\"")
        }
        if let vinAddress {
            fields.append("\"vin\": [{ \"n\": 0, \"isAddress\": true, \"addresses\": [\"\(vinAddress)\"] }]")
        }
        if let voutAddress {
            fields.append(
                "\"vout\": [{ \"value\": \"1000000\", \"n\": 0, \"isAddress\": true, \"addresses\": [\"\(voutAddress)\"] }]"
            )
        }

        return "{ \(fields.joined(separator: ", ")) }"
    }

    private func decodeResponse(transaction: String) throws -> BlockBookAddressResponse {
        let json = """
        {
          "page": 1,
          "totalPages": 1,
          "itemsOnPage": 25,
          "address": "\(walletAddress)",
          "balance": "0",
          "txs": 1,
          "transactions": [\(transaction)]
        }
        """

        return try JSONDecoder().decode(BlockBookAddressResponse.self, from: Data(json.utf8))
    }
}
