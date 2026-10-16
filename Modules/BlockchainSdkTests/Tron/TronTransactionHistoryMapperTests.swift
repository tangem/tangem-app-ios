//
//  TronTransactionHistoryMapperTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
@testable import BlockchainSdk
import TangemFoundation
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

    @Test
    func doesNotMatchWalletAddressWithDifferentCase() throws {
        let mapper = TronTransactionHistoryMapper(blockchain: blockchain)
        let response = makeResponse(transactions: [
            .init(fromAddress: walletAddress.lowercased(), toAddress: otherAddress),
        ])

        let records = try mapper.mapToTransactionRecords(response, walletAddress: walletAddress, amountType: .coin)

        #expect(records.isEmpty)
    }

    @Test(arguments: [9, 57, 58])
    func excludesUnsupportedContractTypeFromHistory(contractType: Int) throws {
        let mapper = TronTransactionHistoryMapper(blockchain: blockchain)
        let response = makeResponse(transactions: [
            .init(fromAddress: walletAddress, toAddress: otherAddress, contractType: contractType),
        ])

        let records = try mapper.mapToTransactionRecords(response, walletAddress: walletAddress, amountType: .coin)

        #expect(records.isEmpty)
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

    @Test
    func voteTotalsEveryVoteAndNamesTheFirstWitness() throws {
        let mapper = TronTransactionHistoryMapper(blockchain: blockchain)
        let firstWitness = "TAAAA8HfE9E1y39RczVQ1ZascUEtaSToF1"
        let secondWitness = "TZZZZ8HfE9E1y39RczVQ1ZascUEtaSToF9"
        let response = makeResponse(transactions: [
            .init(
                fromAddress: walletAddress,
                toAddress: walletAddress,
                contractType: nil,
                chainExtraData: makeChainExtraData(
                    contractType: "VoteWitnessContract",
                    votes: [.init(address: firstWitness, count: "7"), .init(address: secondWitness, count: "12")]
                )
            ),
        ])

        let records = try mapper.mapToTransactionRecords(response, walletAddress: walletAddress, amountType: .coin)

        #expect(records.count == 1)
        #expect(records[0].type == .staking(type: .vote, target: firstWitness))
        #expect(records[0].source == .single(.init(address: walletAddress, amount: 19)))
    }

    /// The legacy `voteList` is a dictionary, so the named witness has to survive its arbitrary ordering.
    @Test
    func voteFromLegacyVoteListTotalsEveryVoteAndNamesTheLowestKeyedWitness() throws {
        let mapper = TronTransactionHistoryMapper(blockchain: blockchain)
        let firstWitness = "TAAAA8HfE9E1y39RczVQ1ZascUEtaSToF1"
        let secondWitness = "TZZZZ8HfE9E1y39RczVQ1ZascUEtaSToF9"
        let response = makeResponse(transactions: [
            .init(
                fromAddress: walletAddress,
                toAddress: walletAddress,
                contractType: 4,
                voteList: [secondWitness: 12, firstWitness: 7]
            ),
        ])

        let records = try mapper.mapToTransactionRecords(response, walletAddress: walletAddress, amountType: .coin)

        #expect(records.count == 1)
        #expect(records[0].type == .staking(type: .vote, target: firstWitness))
        #expect(records[0].source == .single(.init(address: walletAddress, amount: 19)))
    }

    // MARK: - Contract calls in the coin history

    @Test("A TRC20 transfer is a plain transfer, whichever field carries the contract type", arguments: [
        TransactionFixtureContractType.integer,
        .chainExtraData,
    ])
    func trc20TransferIsATransfer(contractType: TransactionFixtureContractType) throws {
        let record = try mapCoinContractCall(calldata: transferCalldata, contractType: contractType)

        #expect(record.type == .transfer)
    }

    @Test("Any other contract call keeps its selector", arguments: [
        TransactionFixtureContractType.integer,
        .chainExtraData,
    ])
    func otherContractCallKeepsItsSelector(contractType: TransactionFixtureContractType) throws {
        let otherCalldata = "0x12345678" + transferCalldata.dropFirst(10)

        let record = try mapCoinContractCall(calldata: otherCalldata, contractType: contractType)

        #expect(record.type == .contractMethodIdentifier(id: "0x12345678"))
    }

    @Test("An approve names its spender as a TRON address, whichever way the address slot is padded", arguments: [
        "41",
        "00",
    ])
    func approveNamesItsSpender(addressPrefix: String) throws {
        let record = try mapCoinContractCall(
            calldata: approveCalldata(addressPrefix: addressPrefix, amount: String(repeating: "f", count: 64)),
            contractType: .chainExtraData
        )

        #expect(record.type == .approve(.init(spender: otherAddress, symbol: "USDT", allowance: .unlimited)))
    }

    @Test("An approve carries the allowance it granted, scaled by the approved token's decimals", arguments: [
        (String(repeating: "0", count: 59) + "f4240", TransactionRecord.TransactionType.Approve.Allowance.limited(1)),
        (String(repeating: "0", count: 64), .revoked),
    ])
    func approveCarriesItsAllowance(amount: String, allowance: TransactionRecord.TransactionType.Approve.Allowance) throws {
        let record = try mapCoinContractCall(
            calldata: approveCalldata(addressPrefix: "41", amount: amount),
            contractType: .integer
        )

        #expect(record.type == .approve(.init(spender: otherAddress, symbol: "USDT", allowance: allowance)))
        #expect(record.destination == .single(.init(address: .contract(usdtContract), amount: 0)))
    }

    @Test("A selector Blockbook parsed wins over the raw call data")
    func parsedSelectorWinsOverRawCallData() throws {
        let record = try mapCoinContractCall(
            calldata: transferCalldata,
            parsedMethodId: "0x12345678",
            contractType: .chainExtraData
        )

        #expect(record.type == .contractMethodIdentifier(id: "0x12345678"))
    }

    @Test("A selector Blockbook parsed wins over call data that looks like an approve")
    func parsedSelectorWinsOverApproveCallData() throws {
        let record = try mapCoinContractCall(
            calldata: approveCalldata(addressPrefix: "41", amount: String(repeating: "f", count: 64)),
            parsedMethodId: "0x12345678",
            contractType: .chainExtraData
        )

        #expect(record.type == .contractMethodIdentifier(id: "0x12345678"))
    }

    @Test("A selector Blockbook parsed without its hex prefix is still recognized")
    func parsedSelectorWithoutHexPrefixIsRecognized() throws {
        let record = try mapCoinContractCall(
            calldata: transferCalldata,
            parsedMethodId: "a9059cbb",
            contractType: .chainExtraData
        )

        #expect(record.type == .transfer)
    }

    @Test("A contract call without call data keeps the type it had", arguments: [
        TransactionFixtureContractType.integer,
        .chainExtraData,
    ])
    func contractCallWithoutCallDataKeepsItsType(contractType: TransactionFixtureContractType) throws {
        let record = try mapCoinContractCall(calldata: nil, contractType: contractType)

        switch contractType {
        case .integer:
            #expect(record.type == .contractMethodIdentifier(id: "TriggerSmartContract"))
        case .chainExtraData:
            #expect(record.type == .transfer)
        }
    }

    @Test("A contract call is addressed to the contract, whichever field carries the contract type", arguments: [
        TransactionFixtureContractType.integer,
        .chainExtraData,
    ])
    func contractCallIsAddressedToTheContract(contractType: TransactionFixtureContractType) throws {
        let record = try mapCoinContractCall(calldata: transferCalldata, contractType: contractType)

        #expect(record.destination == .single(.init(address: .contract(usdtContract), amount: 0)))
    }

    @Test("A TRC20 transfer Blockbook reported without its token transfer gets one from the call data")
    func trc20TransferWithoutTokenTransfersIsDecoded() throws {
        let record = try mapCoinContractCall(calldata: transferCalldata, contractType: .chainExtraData)

        #expect(record.tokenTransfers == [
            TransactionRecord.TokenTransfer(
                source: walletAddress,
                destination: otherAddress,
                amount: 1_000_000,
                name: nil,
                symbol: "USDT",
                decimals: 6,
                contract: usdtContract
            ),
        ])
    }

    @Test("The token transfers Blockbook reported win over the call data")
    func reportedTokenTransfersWinOverCallData() throws {
        let reported = BlockBookAddressResponse.TokenTransfer(
            type: "TRC20",
            from: walletAddress,
            to: "TJRyWwFs9wTFGZg3JbrVriFbNfCug5tDeC",
            contract: usdtContract,
            token: nil,
            name: "Tether USD",
            symbol: "USDT",
            decimals: 6,
            value: "5"
        )

        let record = try mapCoinContractCall(calldata: transferCalldata, contractType: .chainExtraData, tokenTransfers: [reported])

        #expect(record.tokenTransfers.map(\.amount) == [5])
    }

    // MARK: - Token history

    @Test
    func poisonedTransactionProducesNoVisibleUSDTRecords() throws {
        let lookalikeAddress = "TLookalikeAddress0000000000000000000"
        let fakeContract = "TFakeTokenContract000000000000000000"
        let records = try mapTokenTransfers([
            makeTokenTransfer(to: lookalikeAddress, contract: fakeContract, value: "1500000000"),
            makeTokenTransfer(to: otherAddress, contract: usdtContract, value: "0"),
        ], transactionSourceAddress: otherAddress)

        #expect(records.count == 1)
        #expect(records[0].destination == .single(.init(address: .user(otherAddress), amount: 0)))
        #expect(visibleTokenRecords(records).isEmpty)
    }

    @Test
    func mapsUSDTTransferFromRequestedContract() throws {
        let records = try mapTokenTransfers([
            makeTokenTransfer(to: otherAddress, contract: usdtContract, value: "1500000000"),
        ])

        #expect(records.count == 1)
        #expect(records[0].destination == .single(.init(address: .user(otherAddress), amount: 1500)))
    }

    @Test
    func mapsUSDTTransferWhenContractIsInTokenField() throws {
        let records = try mapTokenTransfers([
            makeTokenTransfer(to: otherAddress, token: usdtContract, value: "1500000000"),
        ])

        #expect(records.count == 1)
        #expect(records[0].destination == .single(.init(address: .user(otherAddress), amount: 1500)))
    }

    @Test
    func doesNotMatchTokenContractWithDifferentCase() throws {
        let records = try mapTokenTransfers([
            makeTokenTransfer(to: otherAddress, contract: usdtContract.lowercased(), value: "1500000000"),
        ])

        #expect(records.isEmpty)
    }

    // MARK: - A NowNodes response

    @Test("TRC20 transfers from a NowNodes response are transfers to the contract, with the fee the wallet paid")
    func trc20TransfersFromANowNodesResponse() throws {
        let mapper = TronTransactionHistoryMapper(blockchain: blockchain)
        let response = try JSONDecoder().decode(BlockBookAddressResponse.self, from: Data(nowNodesTRC20Response.utf8))

        let records = try mapper.mapToTransactionRecords(response, walletAddress: walletAddress, amountType: .coin)

        #expect(records.map(\.hash) == ["paidtransfer", "gaslesscompensation", "gaslesstransfer"])
        #expect(records.allSatisfy { $0.type == .transfer && $0.isOutgoing })
        #expect(records.allSatisfy { $0.destination == .single(.init(address: .contract(usdtContract), amount: 0)) })
        #expect(records.map(\.fee.amount.value) == [Decimal(string: "6.4285")!, 0, 0])
        #expect(records.map { $0.tokenTransfers.map(\.destination) } == [
            [otherAddress],
            ["TSWsmaEDgWaE2VsP9tCBGh5GbBRbrdHSuZ"],
            [otherAddress],
        ])
    }

    // MARK: - Helpers

    private var nowNodesTRC20Response: String {
        let transactions = [
            nowNodesTRC20Transaction(
                txid: "paidtransfer",
                recipient: otherAddress,
                rawAmount: "46000000",
                calldata: "0xa9059cbb000000000000000000000041a346f2bd7d43a5d90b7c57a18196be96b2840e61"
                    + "0000000000000000000000000000000000000000000000000000000002bde780",
                totalFee: "6428500"
            ),
            nowNodesTRC20Transaction(
                txid: "gaslesscompensation",
                recipient: "TSWsmaEDgWaE2VsP9tCBGh5GbBRbrdHSuZ",
                rawAmount: "2115586",
                calldata: "0xa9059cbb000000000000000000000041b57f44d21cac5218c0a86b8758dc65427d3530c6"
                    + "0000000000000000000000000000000000000000000000000000000000204802",
                totalFee: nil
            ),
            nowNodesTRC20Transaction(
                txid: "gaslesstransfer",
                recipient: otherAddress,
                rawAmount: "2000000",
                calldata: "0xa9059cbb000000000000000000000041a346f2bd7d43a5d90b7c57a18196be96b2840e61"
                    + "00000000000000000000000000000000000000000000000000000000001e8480",
                totalFee: nil
            ),
        ]

        return """
        {
          "page": 1, "totalPages": 1, "itemsOnPage": 100, "address": "\(walletAddress)", "balance": "12535259",
          "unconfirmedBalance": "0", "unconfirmedTxs": 0, "txs": 3, "nonTokenTxs": 0,
          "transactions": [\(transactions.joined(separator: ","))],
          "tokens": [{ "type": "TRC20", "name": "Tether USD", "contract": "\(usdtContract)", "transfers": 3, "symbol": "USDT", "decimals": 6 }]
        }
        """
    }

    private func nowNodesTRC20Transaction(
        txid: String,
        recipient: String,
        rawAmount: String,
        calldata: String,
        totalFee: String?
    ) -> String {
        let fee = totalFee.map { #", "totalFee": "\#($0)""# } ?? ""

        return """
        {
          "txid": "\(txid)",
          "vin": [{ "n": 0, "addresses": ["\(walletAddress)"], "isAddress": true, "isOwn": true }],
          "vout": [{ "value": "0", "n": 0, "addresses": ["\(usdtContract)"], "isAddress": true }],
          "blockHash": "00000000052bb957a71f916362e60782f100db7e3a0c0a212235c107c61be88f", "blockHeight": 86751575,
          "confirmations": 91972, "blockTime": 1790927343, "value": "0", "fees": "0",
          "chainExtraData": {
            "payloadType": "tron",
            "payload": { "contractType": "TriggerSmartContract", "operation": "contractCall", "bandwidthUsage": "345"\(fee) }
          },
          "tokenTransfers": [{
            "type": "TRC20", "standard": "TRC20", "from": "\(walletAddress)", "to": "\(recipient)",
            "contract": "\(usdtContract)", "name": "Tether USD", "symbol": "USDT", "decimals": 6, "value": "\(rawAmount)"
          }],
          "ethereumSpecific": {
            "type": 1, "createdContract": "\(usdtContract)", "status": 1, "nonce": 0, "gasLimit": 0,
            "data": "\(calldata)", "parsedData": { "methodId": "0xa9059cbb", "name": "" }
          }
        }
        """
    }

    private var usdtContract: String { "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t" }

    private var transferCalldata: String {
        "0xa9059cbb" + String(repeating: "00", count: 11) + "41a346f2bd7d43a5d90b7c57a18196be96b2840e61"
            + String(repeating: "0", count: 59) + "f4240"
    }

    private func mapTokenTransfers(
        _ tokenTransfers: [BlockBookAddressResponse.TokenTransfer],
        transactionSourceAddress: String? = nil
    ) throws -> [TransactionRecord] {
        let mapper = TronTransactionHistoryMapper(blockchain: blockchain)
        let transaction = BlockBookAddressResponse.Transaction(
            fromAddress: transactionSourceAddress ?? walletAddress,
            toAddress: usdtContract,
            value: "0",
            fees: "345000",
            contractType: 31,
            tokenTransfers: tokenTransfers
        )
        let usdt = BlockBookAddressResponse.Token(
            type: "TRC20",
            id: nil,
            name: "Tether USD",
            contract: usdtContract,
            transfers: 1,
            symbol: "USDT",
            decimals: 6,
            balance: nil
        )
        let token = Token(
            name: "Tether USD",
            symbol: "USDT",
            contractAddress: usdtContract,
            decimalCount: 6
        )

        return try mapper.mapToTransactionRecords(
            makeResponse(transactions: [transaction], tokens: [usdt]),
            walletAddress: walletAddress,
            amountType: .token(value: token)
        )
    }

    private func makeTokenTransfer(
        to destination: String,
        contract: String? = nil,
        token: String? = nil,
        value: String
    ) -> BlockBookAddressResponse.TokenTransfer {
        BlockBookAddressResponse.TokenTransfer(
            type: "TRC20",
            from: walletAddress,
            to: destination,
            contract: contract,
            token: token,
            name: "Tether USD",
            symbol: "USDT",
            decimals: 6,
            value: value
        )
    }

    private func visibleTokenRecords(_ records: [TransactionRecord]) -> [TransactionRecord] {
        records.filter { record in
            switch record.destination {
            case .single(let destination):
                return destination.amount != 0
            case .multiple(let destinations):
                return destinations.contains { $0.amount != 0 }
            }
        }
    }

    private func approveCalldata(addressPrefix: String, amount: String) -> String {
        "0x095ea7b3" + String(repeating: "00", count: 11) + addressPrefix + "a346f2bd7d43a5d90b7c57a18196be96b2840e61" + amount
    }

    private func mapCoinContractCall(
        calldata: String?,
        parsedMethodId: String? = nil,
        contractType: TransactionFixtureContractType,
        tokenTransfers: [BlockBookAddressResponse.TokenTransfer]? = nil
    ) throws -> TransactionRecord {
        let mapper = TronTransactionHistoryMapper(blockchain: blockchain)
        let transaction = BlockBookAddressResponse.Transaction(
            fromAddress: walletAddress,
            toAddress: usdtContract,
            value: "0",
            fees: "345000",
            contractType: contractType == .integer ? 31 : nil,
            contractName: contractType == .integer ? "TriggerSmartContract" : nil,
            chainExtraData: contractType == .chainExtraData ? makeChainExtraData(contractType: "TriggerSmartContract") : nil,
            tokenTransfers: tokenTransfers,
            ethereumSpecific: .init(
                status: .ok,
                nonce: nil,
                gasLimit: nil,
                gasUsed: nil,
                gasPrice: nil,
                data: calldata,
                parsedData: parsedMethodId.map { .init(methodId: $0, name: "") }
            )
        )
        let usdt = BlockBookAddressResponse.Token(
            type: "TRC20",
            id: nil,
            name: usdtContract,
            contract: usdtContract,
            transfers: 1,
            symbol: "USDT",
            decimals: 6,
            balance: nil
        )

        let records = try mapper.mapToTransactionRecords(
            makeResponse(transactions: [transaction], tokens: [usdt]),
            walletAddress: walletAddress,
            amountType: .coin
        )

        return try #require(records.singleElement)
    }

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
        votes: [BlockBookAddressResponse.ChainExtraData.Payload.Vote]? = nil,
        claimedVoteReward: String? = nil,
        totalFee: String? = nil
    ) -> BlockBookAddressResponse.ChainExtraData {
        BlockBookAddressResponse.ChainExtraData(
            payloadType: payloadType,
            payload: .init(
                contractType: contractType,
                operation: nil,
                bandwidthUsage: nil,
                votes: votes,
                claimedVoteReward: claimedVoteReward,
                totalFee: totalFee
            )
        )
    }

    private func makeResponse(
        transactions: [BlockBookAddressResponse.Transaction],
        tokens: [BlockBookAddressResponse.Token]? = nil
    ) -> BlockBookAddressResponse {
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
            tokens: tokens
        )
    }
}

// MARK: - Test fixtures

enum TransactionFixtureContractType {
    case integer
    case chainExtraData
}

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
        ethereumSpecific: BlockBookAddressResponse.EthereumSpecific? = nil,
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
            ethereumSpecific: ethereumSpecific,
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
