//
//  EtherscanTransactionHistoryMapperDestinationTests.swift
//  BlockchainSdkTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
@testable import BlockchainSdk
import Testing

/// Etherscan answers a token history with the transfers themselves: `to` is whoever received the tokens and
/// `contractAddress` names the token. A contract call, on the other hand, is reported by the plain transaction
/// endpoint, where `to` is the contract the wallet called and there is no `contractAddress` at all.
struct EtherscanTransactionHistoryMapperDestinationTests {
    private let blockchain = Blockchain.polygon(testnet: false)
    private let walletAddress = "0xcc4855a110a53dcf7392620ab5b2da1d9a0c44ed"
    private let recipient = "0xc5817772d0fcb93e0c8d855724b2cd2ad58a8aed"
    private let tokenContract = "0x3c499c542cef5e3811e1192ce70d8cc03d5c3359"

    @Test("A transfer carried by a contract method keeps the address it paid")
    func tokenTransferThroughAContractMethodNamesTheRecipient() throws {
        let records = try mapTokenTransfer(methodId: "0x4b072692", functionName: "executeTransaction(tuple transaction)")

        let record = try #require(records.first)
        #expect(record.destination == .single(.init(address: .user(recipient), amount: Decimal(stringValue: "17.984408")!)))
        #expect(record.type == .contractMethodIdentifier(id: "0x4b072692"))
    }

    @Test("A plain token transfer is unaffected")
    func plainTokenTransferNamesTheRecipient() throws {
        let records = try mapTokenTransfer(methodId: nil, functionName: "transfer(address to, uint256 value)")

        #expect(try #require(records.first).destination.destinations.first?.address == .user(recipient))
    }

    @Test("A contract call of its own still names the contract it was sent to")
    func contractCallNamesTheContract() throws {
        let mapper = EtherscanTransactionHistoryMapper(blockchain: blockchain)
        let response = EtherscanTransactionHistoryResult(
            status: "1",
            message: nil,
            result: .transactions([
                .init(
                    confirmations: "10",
                    contractAddress: nil,
                    from: walletAddress,
                    functionName: "swap(address executor, tuple desc)",
                    methodId: "0xe21fd0e9",
                    gasPrice: "30000000000",
                    gasUsed: "46000",
                    hash: "0xdeadbeef",
                    input: "0xe21fd0e9",
                    isError: "0",
                    timeStamp: "1700000000",
                    to: tokenContract,
                    txReceiptStatus: "1",
                    value: "0"
                ),
            ])
        )

        let records = try mapper.mapToTransactionRecords(response, walletAddress: walletAddress, amountType: .coin)

        #expect(try #require(records.first).destination.destinations.first?.address == .contract(tokenContract))
    }

    // MARK: - Helpers

    private func mapTokenTransfer(methodId: String?, functionName: String?) throws -> [TransactionRecord] {
        let mapper = EtherscanTransactionHistoryMapper(blockchain: blockchain)
        let token = Token(
            name: "USDC",
            symbol: "USDC",
            contractAddress: tokenContract,
            decimalCount: 6,
            id: "usd-coin"
        )
        let response = EtherscanTransactionHistoryResult(
            status: "1",
            message: nil,
            result: .transactions([
                .init(
                    confirmations: "10",
                    contractAddress: tokenContract,
                    from: walletAddress,
                    functionName: functionName,
                    methodId: methodId,
                    gasPrice: "30000000000",
                    gasUsed: "46000",
                    hash: "0xd8e88fe0075bab52d39a00adff6cdb669e572f9ea670f54728c16ad0ea54c60e",
                    input: methodId,
                    isError: "0",
                    timeStamp: "1700000000",
                    to: recipient,
                    txReceiptStatus: "1",
                    value: "17984408"
                ),
            ])
        )

        return try mapper.mapToTransactionRecords(response, walletAddress: walletAddress, amountType: .token(value: token))
    }
}
