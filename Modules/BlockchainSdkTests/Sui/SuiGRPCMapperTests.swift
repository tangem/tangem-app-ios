//
//  SuiGRPCMapperTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import BlockchainSdk

@Suite("SuiGRPCMapper")
struct SuiGRPCMapperTests {
    private let mapper = SuiGRPCMapper()
    private let address = "0xb50d4a4040facf85dd738c2be57ba55b80af1e0e458b3beddb792aa49c3a4052"
    private let paddedSui = "0x0000000000000000000000000000000000000000000000000000000000000002::sui::SUI"
    private let usdc = "0xdba34672e30cb065b1f93e3ab55318768fd6fef66c15942c9f7cb846e2f900e7::usdc::USDC"

    // MARK: - Requests

    @Test
    func listCoinsRequestWithoutCursor() throws {
        let request = try mapper.makeListCoinsRequest(address: address, cursor: nil)

        #expect(request.owner == address)
        #expect(request.objectType == "0x2::coin::Coin")
        #expect(request.pageSize == 1000)
        #expect(!request.hasPageToken)
        #expect(Set(request.readMask.paths) == ["object_id", "version", "digest", "object_type", "balance", "previous_transaction"])
    }

    @Test
    func listCoinsRequestDecodesCursor() throws {
        let token = Data([0x01, 0x02, 0x03])
        let request = try mapper.makeListCoinsRequest(address: address, cursor: token.base64EncodedString())

        #expect(request.pageToken == token)
    }

    @Test
    func listCoinsRequestRejectsInvalidCursor() {
        #expect(throws: BlockchainSdkError.self) {
            try mapper.makeListCoinsRequest(address: address, cursor: "%%%")
        }
    }

    @Test
    func getEpochRequestReadsReferenceGasPrice() {
        let request = mapper.makeGetEpochRequest()

        #expect(!request.hasEpoch)
        #expect(request.readMask.paths == ["reference_gas_price"])
    }

    @Test
    func simulateRequestCarriesTransactionBytes() throws {
        let bytes = Data([0xAA, 0xBB, 0xCC])
        let request = try mapper.makeSimulateTransactionRequest(transaction: bytes.base64EncodedString())

        #expect(request.transaction.bcs.value == bytes)
        #expect(!request.transaction.bcs.hasName)
        #expect(request.readMask.paths == [
            "transaction.effects.status",
            "transaction.effects.gas_used",
            "transaction.transaction.gas_payment.price",
        ])
    }

    @Test
    func simulateRequestRejectsEmptyTransaction() {
        #expect(throws: BlockchainSdkError.self) {
            try mapper.makeSimulateTransactionRequest(transaction: "")
        }
    }

    @Test
    func executeRequestCarriesTransactionAndSignature() throws {
        let bytes = Data([0x01, 0x02])
        let signature = Data([0x00, 0x10, 0x20])

        let request = try mapper.makeExecuteTransactionRequest(
            transaction: bytes.base64EncodedString(),
            signature: signature.base64EncodedString()
        )

        #expect(request.transaction.bcs.value == bytes)
        #expect(request.signatures.map(\.bcs.value) == [signature])
        #expect(request.readMask.paths == ["digest"])
    }

    // MARK: - Coins

    @Test
    func mapsCoinObjectsAndNormalizesSuiType() throws {
        var response = Sui_Rpc_V2_ListOwnedObjectsResponse()
        response.objects = [
            makeObject(id: "0x1", type: "0x0000000000000000000000000000000000000000000000000000000000000002::coin::Coin<\(paddedSui)>", balance: 100),
            makeObject(id: "0x2", type: "0x2::coin::Coin<\(usdc)>", balance: 5),
        ]

        let coins = try mapper.mapToCoins(response: response)

        #expect(!coins.hasNextPage)
        #expect(coins.nextCursor == nil)
        #expect(coins.data.map(\.coinType) == ["0x2::sui::SUI", usdc])
        #expect(coins.data.map(\.balance) == ["100", "5"])
        #expect(coins.data.first?.coinObjectId == "0x1")
        #expect(coins.data.first?.version == "7")
        #expect(coins.data.first?.digest == "digest_0x1")
    }

    @Test
    func skipsObjectsWithoutCoinTypeParameter() throws {
        var response = Sui_Rpc_V2_ListOwnedObjectsResponse()
        response.objects = [makeObject(id: "0x1", type: "0x2::coin::Coin", balance: 1)]

        let coins = try mapper.mapToCoins(response: response)

        #expect(coins.data.isEmpty)
    }

    @Test
    func failsOnObjectWithMissingFields() {
        var object = Sui_Rpc_V2_Object()
        object.objectID = "0x1"

        var response = Sui_Rpc_V2_ListOwnedObjectsResponse()
        response.objects = [object]

        #expect(throws: BlockchainSdkError.self) {
            try mapper.mapToCoins(response: response)
        }
    }

    @Test
    func mapsNextPageTokenToCursor() throws {
        let token = Data([0x09, 0x08])
        var response = Sui_Rpc_V2_ListOwnedObjectsResponse()
        response.nextPageToken = token

        let coins = try mapper.mapToCoins(response: response)

        #expect(coins.hasNextPage)
        #expect(coins.nextCursor == token.base64EncodedString())
    }

    @Test(arguments: [
        ("0x2::sui::SUI", "0x2::sui::SUI"),
        ("0x0000000000000000000000000000000000000000000000000000000000000002::sui::SUI", "0x2::sui::SUI"),
        ("0x12::sui::SUI", "0x12::sui::SUI"),
        ("0xabc::usdc::USDC", "0xabc::usdc::USDC"),
    ])
    func normalizesCoinType(input: String, expected: String) {
        #expect(mapper.normalizeCoinType(input) == expected)
    }

    // MARK: - Gas price

    @Test
    func mapsReferenceGasPrice() throws {
        var response = Sui_Rpc_V2_GetEpochResponse()
        response.epoch.referenceGasPrice = 750

        #expect(try mapper.mapToReferenceGasPrice(response: response) == "750")
    }

    @Test
    func failsWithoutReferenceGasPrice() {
        #expect(throws: BlockchainSdkError.self) {
            try mapper.mapToReferenceGasPrice(response: Sui_Rpc_V2_GetEpochResponse())
        }
    }

    // MARK: - Simulate

    @Test(arguments: [true, false])
    func mapsSimulateResponse(isSuccess: Bool) throws {
        var response = Sui_Rpc_V2_SimulateTransactionResponse()
        response.transaction.effects.status.success = isSuccess
        response.transaction.effects.gasUsed.computationCost = 1_000_000
        response.transaction.effects.gasUsed.storageCost = 1_976_000
        response.transaction.effects.gasUsed.storageRebate = 978_120
        response.transaction.transaction.gasPayment.price = 750

        let inspect = try mapper.mapToInspectTransaction(response: response)

        #expect(inspect.effects.isSuccess() == isSuccess)
        #expect(inspect.effects.gasUsed.computationCost == "1000000")
        #expect(inspect.effects.gasUsed.storageCost == "1976000")
        #expect(inspect.effects.gasUsed.storageRebate == "978120")
        #expect(inspect.input.gasData.price == "750")
    }

    @Test
    func simulateWithoutStatusIsFailure() throws {
        var response = Sui_Rpc_V2_SimulateTransactionResponse()
        response.transaction.effects.gasUsed.computationCost = 1
        response.transaction.transaction.gasPayment.price = 750

        let inspect = try mapper.mapToInspectTransaction(response: response)

        #expect(!inspect.effects.isSuccess())
    }

    @Test
    func simulateFailsWithoutGasPrice() {
        var response = Sui_Rpc_V2_SimulateTransactionResponse()
        response.transaction.effects.gasUsed.computationCost = 1

        #expect(throws: BlockchainSdkError.self) {
            try mapper.mapToInspectTransaction(response: response)
        }
    }

    // MARK: - Execute

    @Test(arguments: [true, false])
    func mapsExecuteResponseDigestRegardlessOfStatus(isSuccess: Bool) throws {
        var response = Sui_Rpc_V2_ExecuteTransactionResponse()
        response.transaction.digest = "digest"
        response.transaction.effects.status.success = isSuccess

        #expect(try mapper.mapToExecuteTransaction(response: response).digest == "digest")
    }

    @Test
    func mapsExecuteResponseDigestWithoutStatus() throws {
        var response = Sui_Rpc_V2_ExecuteTransactionResponse()
        response.transaction.digest = "digest"

        #expect(try mapper.mapToExecuteTransaction(response: response).digest == "digest")
    }

    @Test
    func executeFailsWithoutDigest() {
        let response = Sui_Rpc_V2_ExecuteTransactionResponse()

        #expect(throws: BlockchainSdkError.self) {
            try mapper.mapToExecuteTransaction(response: response)
        }
    }

    // MARK: - Balances

    @Test
    func listBalancesRequestCarriesPageToken() {
        let pageToken = Data([0x01, 0x02])

        let request = mapper.makeListBalancesRequest(address: address, pageToken: pageToken)

        #expect(request.owner == address)
        #expect(request.pageSize == 1000)
        #expect(request.pageToken == pageToken)
        #expect(!mapper.makeListBalancesRequest(address: address, pageToken: nil).hasPageToken)
    }

    @Test
    func mapsBalancesAndNormalizesSuiType() throws {
        var response = Sui_Rpc_V2_ListBalancesResponse()
        response.balances = [
            makeBalance(coinType: paddedSui, balance: 3000, addressBalance: 2000),
            makeBalance(coinType: usdc, balance: 500, addressBalance: 0),
        ]

        let balances = try mapper.mapToBalances(response: response)

        #expect(balances.count == 2)
        #expect(balances[0].coinType == .sui)
        #expect(balances[0].balance == 3000)
        #expect(balances[0].addressBalance == 2000)
        #expect(try balances[1].coinType == SuiCoinObject.CoinType(string: usdc))
        #expect(balances[1].balance == 500)
        #expect(balances[1].addressBalance == 0)
    }

    @Test
    func skipsBalancesWithGenericCoinType() throws {
        var response = Sui_Rpc_V2_ListBalancesResponse()
        response.balances = [makeBalance(coinType: "0x2::lp::LP<0x2::sui::SUI, \(usdc)>", balance: 1, addressBalance: 1)]

        #expect(try mapper.mapToBalances(response: response).isEmpty)
    }

    @Test
    func skipsBalancesWithoutKnownCoinType() throws {
        var balanceWithoutCoinType = Sui_Rpc_V2_Balance()
        balanceWithoutCoinType.balance = 1

        var genericBalanceWithoutTotal = Sui_Rpc_V2_Balance()
        genericBalanceWithoutTotal.coinType = "0x2::lp::LP<0x2::sui::SUI, \(usdc)>"

        var response = Sui_Rpc_V2_ListBalancesResponse()
        response.balances = [
            balanceWithoutCoinType,
            genericBalanceWithoutTotal,
            makeBalance(coinType: paddedSui, balance: 7, addressBalance: 2),
        ]

        let balances = try mapper.mapToBalances(response: response)

        #expect(balances.count == 1)
        #expect(balances.first?.coinType == .sui)
        #expect(balances.first?.balance == 7)
    }

    @Test
    func failsOnBalanceWithoutTotal() {
        var balance = Sui_Rpc_V2_Balance()
        balance.coinType = paddedSui

        var response = Sui_Rpc_V2_ListBalancesResponse()
        response.balances = [balance]

        #expect(throws: BlockchainSdkError.self) {
            try mapper.mapToBalances(response: response)
        }
    }

    // MARK: - Service info

    @Test
    func mapsServiceInfo() throws {
        var response = Sui_Rpc_V2_GetServiceInfoResponse()
        response.chainID = "4btiuiMPvEENsttpZC7CZ53DruC3MAgfznDbASZ7DR6S"
        response.epoch = 1292

        let serviceInfo = try mapper.mapToServiceInfo(response: response)

        #expect(serviceInfo.chainIdentifier == "4btiuiMPvEENsttpZC7CZ53DruC3MAgfznDbASZ7DR6S")
        #expect(serviceInfo.epoch == 1292)
    }

    @Test
    func serviceInfoFailsWithoutChainIdentifier() {
        var response = Sui_Rpc_V2_GetServiceInfoResponse()
        response.epoch = 1292

        #expect(throws: BlockchainSdkError.self) {
            try mapper.mapToServiceInfo(response: response)
        }
    }
}

// MARK: - Helpers

private extension SuiGRPCMapperTests {
    func makeObject(id: String, type: String, balance: UInt64) -> Sui_Rpc_V2_Object {
        var object = Sui_Rpc_V2_Object()
        object.objectID = id
        object.version = 7
        object.digest = "digest_\(id)"
        object.objectType = type
        object.balance = balance
        return object
    }

    func makeBalance(coinType: String, balance: UInt64, addressBalance: UInt64) -> Sui_Rpc_V2_Balance {
        var result = Sui_Rpc_V2_Balance()
        result.coinType = coinType
        result.balance = balance
        result.addressBalance = addressBalance
        return result
    }
}
