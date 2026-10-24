//
//  EthereumTransactionHistoryMapperSafeExecutionTests.swift
//  BlockchainSdkTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
@testable import BlockchainSdk
import Testing

struct EthereumTransactionHistoryMapperSafeExecutionTests {
    private let blockchain = Blockchain.ethereum(testnet: false)
    private let safeAddress = "0x90e4d59c8583e37426b37d1d7394b6008a987c67"
    private let recipient = "0xc5817772d0fcb93e0c8d855724b2cd2ad58a8aed"
    private let tokenContract = "0xdac17f958d2ee523a2206206994597c13d831ec7"
    private let oneCoin: BigUInt = 1_000_000_000_000_000_000
    private let refundFee = Decimal(1) / 10_000

    @Test("A coin sent by the Safe is an outgoing transfer to the recipient with the refund cap as the fee")
    func coinTransfer() throws {
        let transaction = BlockBookAddressResponse.Transaction.execTransaction(safe: safeAddress, calldata: coinTransferCalldata)
        let record = try #require(map(transaction, amountType: .coin).first)

        #expect(record.isOutgoing)
        #expect(record.type == .transfer)
        #expect(record.source == .single(.init(address: safeAddress, amount: 1)))
        #expect(record.destination == .single(.init(address: .user(recipient), amount: 1)))
        #expect(record.fee.amount.value == refundFee)
    }

    @Test("Leaves the record alone for a wallet that is not a Safe, a delegatecall and a failed transaction")
    func recordsLeftAlone() throws {
        let delegateCall = SafeExecTransactionCalldata.make(to: recipient, value: 0, operation: 1)

        let records = try [
            map(.execTransaction(safe: safeAddress, calldata: coinTransferCalldata), amountType: .coin, isSafe: false),
            map(.execTransaction(safe: safeAddress, calldata: delegateCall), amountType: .coin),
            map(.execTransaction(safe: safeAddress, calldata: coinTransferCalldata, status: .failure), amountType: .coin),
        ].map { try #require($0.first) }

        for record in records {
            #expect(!record.isOutgoing)
            #expect(record.type == .contractMethodIdentifier(id: SafeExecTransactionMethod.methodId))
        }
    }

    @Test("A token transfer the Safe executed is a transfer in the token history with the refund cap as the fee")
    func tokenHistory() throws {
        let token = Token(name: "Tether USD", symbol: "USDT", contractAddress: tokenContract, decimalCount: 6, id: "tether")
        let transfer = try TransferERC20TokenMethod(destination: recipient, amount: 17_984_408).data
        let calldata = SafeExecTransactionCalldata.make(to: tokenContract, value: 0, data: transfer)
        let transaction = BlockBookAddressResponse.Transaction.execTransaction(
            safe: safeAddress,
            calldata: calldata,
            tokenTransfers: [.init(type: "ERC20", from: safeAddress, to: recipient, contract: tokenContract, token: nil, name: "Tether USD", symbol: "USDT", decimals: 6, value: "17984408")]
        )

        let record = try #require(map(transaction, amountType: .token(value: token)).first)

        #expect(record.isOutgoing)
        #expect(record.type == .transfer)
        #expect(record.destination.destinations.first?.address == .user(recipient))
        #expect(record.fee.amount.value == refundFee)
    }

    @Test("A token transfer emitted by any other inner call is a transfer in the token history and an unknown operation in the coin history")
    func otherCallTokenHistory() throws {
        let token = Token(name: "Tether USD", symbol: "USDT", contractAddress: tokenContract, decimalCount: 6, id: "tether")
        let router = "0x6131b5fae19ea4f9d964eac0408e4408b66337b5"
        let calldata = SafeExecTransactionCalldata.make(to: router, value: 0, data: Data(hexString: "0xe21fd0e9"))
        let transaction = BlockBookAddressResponse.Transaction.execTransaction(
            safe: safeAddress,
            calldata: calldata,
            tokenTransfers: [.init(type: "ERC20", from: safeAddress, to: router, contract: tokenContract, token: nil, name: "Tether USD", symbol: "USDT", decimals: 6, value: "17984408")]
        )

        let tokenRecord = try #require(map(transaction, amountType: .token(value: token)).first)
        let coinRecord = try #require(map(transaction, amountType: .coin).first)

        #expect(tokenRecord.isOutgoing)
        #expect(tokenRecord.type == .transfer)
        #expect(tokenRecord.destination.destinations.first?.address == .user(router))
        #expect(coinRecord.type == .unknownOperation)
    }

    // MARK: - Helpers

    private var coinTransferCalldata: String {
        SafeExecTransactionCalldata.make(to: recipient, value: oneCoin)
    }

    private func map(
        _ transaction: BlockBookAddressResponse.Transaction,
        amountType: Amount.AmountType,
        isSafe: Bool = true
    ) throws -> [TransactionRecord] {
        let mapper = EthereumTransactionHistoryMapper(blockchain: blockchain, isSafe: isSafe)
        let response = BlockBookAddressResponse(
            page: 1,
            totalPages: 1,
            itemsOnPage: 25,
            address: safeAddress,
            balance: "0",
            unconfirmedBalance: nil,
            unconfirmedTxs: nil,
            txs: 1,
            nonTokenTxs: nil,
            transactions: [transaction],
            tokens: nil
        )

        return try mapper.mapToTransactionRecords(response, walletAddress: safeAddress, amountType: amountType)
    }
}

// MARK: - Test fixtures

private extension BlockBookAddressResponse.Transaction {
    static func execTransaction(
        safe: String,
        calldata: String,
        status: BlockBookAddressResponse.StatusType = .ok,
        tokenTransfers: [BlockBookAddressResponse.TokenTransfer]? = nil
    ) -> Self {
        .init(
            txid: "0xdeadbeef",
            contractType: nil,
            contractName: nil,
            version: nil,
            vin: [.init(txid: nil, sequence: nil, n: 0, addresses: [SafeExecTransactionCalldata.refundReceiver], isAddress: true, value: nil, hex: nil, vout: nil, isOwn: nil)],
            vout: [.init(value: "0", n: 0, hex: nil, addresses: [safe], isAddress: true, spent: nil, isOwn: nil)],
            blockHash: nil,
            blockHeight: 1,
            confirmations: 1,
            blockTime: 1_700_000_000,
            value: "0",
            valueIn: nil,
            fees: "210000",
            hex: nil,
            tokenTransfers: tokenTransfers,
            ethereumSpecific: .init(status: status, nonce: 1, gasLimit: nil, gasUsed: nil, gasPrice: nil, data: calldata, parsedData: nil),
            chainExtraData: nil,
            tronTXReceipt: nil,
            fromAddress: nil,
            toAddress: nil,
            voteList: nil
        )
    }
}
