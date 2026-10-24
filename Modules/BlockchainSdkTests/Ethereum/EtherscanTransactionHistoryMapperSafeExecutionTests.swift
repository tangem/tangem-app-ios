//
//  EtherscanTransactionHistoryMapperSafeExecutionTests.swift
//  BlockchainSdkTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
@testable import BlockchainSdk
import Testing

struct EtherscanTransactionHistoryMapperSafeExecutionTests {
    private let blockchain = Blockchain.polygon(testnet: false)
    private let safeAddress = "0x90e4d59c8583e37426b37d1d7394b6008a987c67"
    private let recipient = "0xc5817772d0fcb93e0c8d855724b2cd2ad58a8aed"
    private let tokenContract = "0x3c499c542cef5e3811e1192ce70d8cc03d5c3359"
    private let oneCoin: BigUInt = 1_000_000_000_000_000_000
    private let refundFee = Decimal(1) / 10_000

    @Test("A coin sent by the Safe is an outgoing transfer to the recipient with the refund cap as the fee")
    func coinTransfer() throws {
        let record = try #require(mapCoin(input: SafeExecTransactionCalldata.make(to: recipient, value: oneCoin)).first)

        #expect(record.isOutgoing)
        #expect(record.type == .transfer)
        #expect(record.source == .single(.init(address: safeAddress, amount: 1)))
        #expect(record.destination == .single(.init(address: .user(recipient), amount: 1)))
        #expect(record.fee.amount.value == refundFee)
    }

    @Test("A token sent by the Safe leaves the coin history a zero transfer carrying the token transfer")
    func tokenTransferInCoinHistory() throws {
        let transfer = try TransferERC20TokenMethod(destination: recipient, amount: 17_984_408).data
        let record = try #require(mapCoin(input: SafeExecTransactionCalldata.make(to: tokenContract, value: 0, data: transfer)).first)

        #expect(record.isOutgoing)
        #expect(record.type == .transfer)
        #expect(record.destination == .single(.init(address: .contract(tokenContract), amount: 0)))
        #expect(record.tokenTransfers.map(\.source) == [safeAddress])
        #expect(record.tokenTransfers.map(\.destination) == [recipient])
        #expect(record.tokenTransfers.map(\.amount) == [17_984_408])
        #expect(record.fee.amount.value == refundFee)
    }

    @Test("Any other inner call is an unknown operation")
    func otherCall() throws {
        let input = SafeExecTransactionCalldata.make(to: tokenContract, value: 0, data: Data(hexString: "0xe21fd0e9"))
        let record = try #require(mapCoin(input: input).first)

        #expect(record.isOutgoing)
        #expect(record.type == .unknownOperation)
        #expect(record.destination == .single(.init(address: .contract(tokenContract), amount: 0)))
    }

    @Test("Leaves the record alone for a wallet that is not a Safe, a refund in a token and a failed transaction")
    func recordsLeftAlone() throws {
        let input = SafeExecTransactionCalldata.make(to: recipient, value: oneCoin)
        let tokenRefund = SafeExecTransactionCalldata.make(to: recipient, value: oneCoin, gasToken: tokenContract)

        let records = try [
            mapCoin(input: input, isSafe: false),
            mapCoin(input: tokenRefund),
            mapCoin(input: input, isError: "1"),
        ].map { try #require($0.first) }

        for record in records {
            #expect(!record.isOutgoing)
            #expect(record.type == .contractMethodIdentifier(id: SafeExecTransactionMethod.methodId))
        }
    }

    @Test("A token transfer the Safe executed is a transfer in the token history")
    func tokenHistory() throws {
        let token = Token(name: "USDC", symbol: "USDC", contractAddress: tokenContract, decimalCount: 6, id: "usd-coin")
        let mapper = EtherscanTransactionHistoryMapper(blockchain: blockchain, isSafe: true)
        let response = EtherscanTransactionHistoryResult.make([.tokenTransfer(from: safeAddress, to: recipient, contract: tokenContract)])

        let record = try #require(try mapper.mapToTransactionRecords(response, walletAddress: safeAddress, amountType: .token(value: token)).first)

        #expect(record.isOutgoing)
        #expect(record.type == .transfer)
        #expect(record.destination.destinations.first?.address == .user(recipient))
    }

    // MARK: - Helpers

    private func mapCoin(input: String, isSafe: Bool = true, isError: String = "0") throws -> [TransactionRecord] {
        let mapper = EtherscanTransactionHistoryMapper(blockchain: blockchain, isSafe: isSafe)
        let response = EtherscanTransactionHistoryResult.make([.execTransaction(to: safeAddress, input: input, isError: isError)])

        return try mapper.mapToTransactionRecords(response, walletAddress: safeAddress, amountType: .coin)
    }
}

// MARK: - Test fixtures

private extension EtherscanTransactionHistoryResult {
    static func make(_ transactions: [Transaction]) -> Self {
        .init(status: "1", message: nil, result: .transactions(transactions))
    }
}

private extension EtherscanTransactionHistoryResult.Transaction {
    static func execTransaction(to: String, input: String, isError: String) -> Self {
        .init(
            confirmations: "10",
            contractAddress: nil,
            from: SafeExecTransactionCalldata.refundReceiver,
            functionName: "execTransaction(address to, uint256 value, bytes data)",
            methodId: SafeExecTransactionMethod.methodId,
            gasPrice: "30000000000",
            gasUsed: "46000",
            hash: "0xdeadbeef",
            input: input,
            isError: isError,
            timeStamp: "1700000000",
            to: to,
            txReceiptStatus: isError == "1" ? "0" : "1",
            value: "0"
        )
    }

    static func tokenTransfer(from: String, to: String, contract: String) -> Self {
        .init(
            confirmations: "10",
            contractAddress: contract,
            from: from,
            functionName: "execTransaction(address to, uint256 value, bytes data)",
            methodId: SafeExecTransactionMethod.methodId,
            gasPrice: "30000000000",
            gasUsed: "46000",
            hash: "0xdeadbeef",
            input: "deprecated",
            isError: "0",
            timeStamp: "1700000000",
            to: to,
            txReceiptStatus: "1",
            value: "17984408"
        )
    }
}
