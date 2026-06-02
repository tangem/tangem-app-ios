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
        let response = makeResponse(transactions: [
            .init(fromAddress: walletAddress, toAddress: otherAddress),
        ])

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
        let response = makeResponse(transactions: [
            .init(vin: [.init(address: walletAddress)], vout: [.init(address: otherAddress)]),
        ])

        let records = try mapper.mapToTransactionRecords(response, walletAddress: walletAddress, amountType: .coin)

        #expect(records.count == 1)
        #expect(records[0].isOutgoing)
        #expect(records[0].source == .single(.init(address: walletAddress, amount: 1)))
        #expect(records[0].destination == .single(.init(address: .user(otherAddress), amount: 1)))
    }

    @Test
    func mapsIncomingCoinTransferFallingBackToVinVoutAddresses() throws {
        let mapper = TronTransactionHistoryMapper(blockchain: blockchain)
        let response = makeResponse(transactions: [
            .init(vin: [.init(address: otherAddress)], vout: [.init(address: walletAddress)]),
        ])

        let records = try mapper.mapToTransactionRecords(response, walletAddress: walletAddress, amountType: .coin)

        #expect(records.count == 1)
        #expect(!records[0].isOutgoing)
        #expect(records[0].source == .single(.init(address: otherAddress, amount: 1)))
        #expect(records[0].destination == .single(.init(address: .user(walletAddress), amount: 1)))
    }

    @Test
    func prefersDedicatedAddressFieldsOverVinVout() throws {
        let mapper = TronTransactionHistoryMapper(blockchain: blockchain)
        let response = makeResponse(transactions: [
            .init(
                vin: [.init(address: "TWrongVinAddress0000000000000000000")],
                vout: [.init(address: "TWrongVoutAddress000000000000000000")],
                fromAddress: walletAddress,
                toAddress: otherAddress
            ),
        ])

        let records = try mapper.mapToTransactionRecords(response, walletAddress: walletAddress, amountType: .coin)

        #expect(records.count == 1)
        #expect(records[0].source == .single(.init(address: walletAddress, amount: 1)))
        #expect(records[0].destination == .single(.init(address: .user(otherAddress), amount: 1)))
    }

    @Test
    func skipsCoinTransferWhenNeitherAddressNorVinVoutPresent() throws {
        let mapper = TronTransactionHistoryMapper(blockchain: blockchain)
        let response = makeResponse(transactions: [.init()])

        let records = try mapper.mapToTransactionRecords(response, walletAddress: walletAddress, amountType: .coin)

        #expect(records.isEmpty)
    }

    // MARK: - Helpers

    private func makeResponse(transactions: [BlockBookAddressResponse.Transaction]) -> BlockBookAddressResponse {
        BlockBookAddressResponse(
            page: 1,
            totalPages: 1,
            itemsOnPage: 25,
            address: walletAddress,
            balance: "0",
            unconfirmedBalance: nil,
            unconfirmedTxs: nil,
            txs: transactions.count,
            nonTokenTxs: nil,
            transactions: transactions,
            tokens: nil
        )
    }
}

// MARK: - Test fixtures

private extension BlockBookAddressResponse.Transaction {
    /// The production type only declares a `Decodable` initializer, so we provide a memberwise one
    /// for tests with sane defaults (a confirmed 1 TRX coin transfer).
    init(
        vin: [BlockBookAddressResponse.Vin]? = nil,
        vout: [BlockBookAddressResponse.Vout]? = nil,
        fromAddress: String? = nil,
        toAddress: String? = nil,
        value: String = "1000000",
        fees: String = "0",
        contractType: Int? = 1,
        contractName: String? = nil,
        voteList: [String: Int]? = nil,
        tokenTransfers: [BlockBookAddressResponse.TokenTransfer]? = nil,
        tronTXReceipt: BlockBookAddressResponse.TronTXReceipt? = .init(status: .ok)
    ) {
        self.init(
            txid: "abc123deadbeef",
            contractType: contractType,
            contractName: contractName,
            version: nil,
            vin: vin,
            vout: vout,
            blockHash: nil,
            blockHeight: 1,
            confirmations: 1,
            blockTime: 1_700_000_000,
            value: value,
            valueIn: nil,
            fees: fees,
            hex: nil,
            tokenTransfers: tokenTransfers,
            ethereumSpecific: nil,
            tronTXReceipt: tronTXReceipt,
            fromAddress: fromAddress,
            toAddress: toAddress,
            voteList: voteList
        )
    }
}

private extension BlockBookAddressResponse.Vin {
    init(address: String) {
        self.init(txid: nil, sequence: nil, n: 0, addresses: [address], isAddress: true, value: nil, hex: nil, vout: nil, isOwn: nil)
    }
}

private extension BlockBookAddressResponse.Vout {
    init(address: String) {
        self.init(value: "1000000", n: 0, hex: nil, addresses: [address], isAddress: true, spent: nil, isOwn: nil)
    }
}
