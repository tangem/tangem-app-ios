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

    // MARK: - Type extraction from `chainExtraData` (integer `contract_type` absent, [REDACTED_INFO])

    @Test
    func v2NilChainExtraDataMapsToTransfer() throws {
        #expect(try coinTransactionType(chainExtraData: nil) == .transfer)
    }

    @Test
    func v2NonTronPayloadTypeMapsToTransfer() throws {
        let extraData = makeChainExtraData(payloadType: "ethereum", contractType: "VoteWitnessContract")
        #expect(try coinTransactionType(chainExtraData: extraData) == .transfer)
    }

    @Test
    func v2NilPayloadContractTypeMapsToTransfer() throws {
        #expect(try coinTransactionType(chainExtraData: makeChainExtraData(contractType: nil)) == .transfer)
    }

    @Test
    func v2TransferContractMapsToTransfer() throws {
        #expect(try coinTransactionType(chainExtraData: makeChainExtraData(contractType: "TransferContract")) == .transfer)
    }

    @Test
    func v2TriggerSmartContractMapsToTransfer() throws {
        #expect(try coinTransactionType(chainExtraData: makeChainExtraData(contractType: "TriggerSmartContract")) == .transfer)
    }

    @Test
    func v2VoteWitnessContractExposesValidatorFromVotes() throws {
        let validator = "TKSXDA8HfE9E1y39RczVQ1ZascUEtaSToF"
        let extraData = makeChainExtraData(
            contractType: "VoteWitnessContract",
            votes: [.init(address: validator, count: "1")]
        )
        #expect(try coinTransactionType(chainExtraData: extraData) == .staking(type: .vote, target: validator))
    }

    @Test
    func v2VoteWitnessContractWithNilVotesHasNilTarget() throws {
        let extraData = makeChainExtraData(contractType: "VoteWitnessContract", votes: nil)
        #expect(try coinTransactionType(chainExtraData: extraData) == .staking(type: .vote, target: nil))
    }

    @Test
    func v2WithdrawBalanceContractMapsToClaimRewards() throws {
        let extraData = makeChainExtraData(contractType: "WithdrawBalanceContract")
        #expect(try coinTransactionType(chainExtraData: extraData) == .staking(type: .claimRewards, target: nil))
    }

    @Test
    func v2FreezeBalanceV2ContractMapsToStake() throws {
        let extraData = makeChainExtraData(contractType: "FreezeBalanceV2Contract")
        #expect(try coinTransactionType(chainExtraData: extraData) == .staking(type: .stake, target: nil))
    }

    @Test
    func v2UnfreezeBalanceV2ContractMapsToUnstake() throws {
        let extraData = makeChainExtraData(contractType: "UnfreezeBalanceV2Contract")
        #expect(try coinTransactionType(chainExtraData: extraData) == .staking(type: .unstake, target: nil))
    }

    @Test
    func v2WithdrawExpireUnfreezeContractMapsToWithdraw() throws {
        let extraData = makeChainExtraData(contractType: "WithdrawExpireUnfreezeContract")
        #expect(try coinTransactionType(chainExtraData: extraData) == .staking(type: .withdraw, target: nil))
    }

    @Test
    func v2UnknownContractTypeMapsToTransfer() throws {
        let extraData = makeChainExtraData(contractType: "SomethingUnknownContract")
        #expect(try coinTransactionType(chainExtraData: extraData) == .transfer)
    }

    // MARK: - Staking amount: self→self destination zeroed so the app mapper keeps the gross amount

    @Test
    func freezeKeepsGrossSourceAndZeroesDestinationAmount() throws {
        let mapper = TronTransactionHistoryMapper(blockchain: blockchain)
        let response = makeResponse(transactions: [
            .init(
                fromAddress: walletAddress,
                toAddress: walletAddress,
                contractType: nil,
                chainExtraData: makeChainExtraData(contractType: "FreezeBalanceV2Contract")
            ),
        ])

        let records = try mapper.mapToTransactionRecords(response, walletAddress: walletAddress, amountType: .coin)

        #expect(records.count == 1)
        #expect(records[0].type == .staking(type: .stake, target: nil))
        #expect(records[0].source == .single(.init(address: walletAddress, amount: 1)))
        #expect(records[0].destination == .single(.init(address: .user(walletAddress), amount: 0)))
    }

    @Test
    func unfreezeKeepsGrossSourceAndZeroesDestinationAmount() throws {
        let mapper = TronTransactionHistoryMapper(blockchain: blockchain)
        let response = makeResponse(transactions: [
            .init(
                fromAddress: walletAddress,
                toAddress: walletAddress,
                contractType: nil,
                chainExtraData: makeChainExtraData(contractType: "UnfreezeBalanceV2Contract")
            ),
        ])

        let records = try mapper.mapToTransactionRecords(response, walletAddress: walletAddress, amountType: .coin)

        #expect(records.count == 1)
        #expect(records[0].type == .staking(type: .unstake, target: nil))
        #expect(records[0].source == .single(.init(address: walletAddress, amount: 1)))
        #expect(records[0].destination == .single(.init(address: .user(walletAddress), amount: 0)))
    }

    // MARK: - Helpers

    /// Maps a single coin transaction whose integer `contract_type` is absent (so the type is taken
    /// from `chainExtraData`) and returns its resolved transaction type.
    private func coinTransactionType(
        chainExtraData: BlockBookAddressResponse.ChainExtraData?
    ) throws -> TransactionRecord.TransactionType {
        let mapper = TronTransactionHistoryMapper(blockchain: blockchain)
        let response = makeResponse(transactions: [
            .init(fromAddress: walletAddress, toAddress: otherAddress, contractType: nil, chainExtraData: chainExtraData),
        ])

        let records = try mapper.mapToTransactionRecords(response, walletAddress: walletAddress, amountType: .coin)
        #expect(records.count == 1)
        return records[0].type
    }

    private func makeChainExtraData(
        payloadType: String? = "tron",
        contractType: String?,
        votes: [BlockBookAddressResponse.ChainExtraData.Payload.Vote]? = nil
    ) -> BlockBookAddressResponse.ChainExtraData {
        BlockBookAddressResponse.ChainExtraData(
            payloadType: payloadType,
            payload: .init(contractType: contractType, operation: nil, bandwidthUsage: nil, votes: votes)
        )
    }

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
        chainExtraData: BlockBookAddressResponse.ChainExtraData? = nil,
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
            chainExtraData: chainExtraData,
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
