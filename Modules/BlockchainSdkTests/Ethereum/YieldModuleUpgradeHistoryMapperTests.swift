//
//  YieldModuleUpgradeHistoryMapperTests.swift
//  BlockchainSdkTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
@testable import BlockchainSdk
import Testing

@Suite("History of a Yield Module call wrapped in an upgrade")
struct YieldModuleUpgradeHistoryMapperTests {
    private let polygon = Blockchain.polygon(testnet: false)
    private let walletAddress = "0x90e4d59c8583e37426b37d1d7394b6008a987c67"
    private let moduleAddress = "0x4444444444444444444444444444444444444444"
    private let recipient = "0x1231deb6f5749ef6ce6943a275a1d3e7486f4eae"
    private let usdc = Token(name: "USD Coin", symbol: "USDC", contractAddress: "0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359", decimalCount: 6)

    private var yieldSend: String {
        YieldModuleUpgradeCalldata.yieldSend(token: usdc.contractAddress, to: recipient, amount: 400_000)
    }

    @Test(
        "An upgrade to a known Yield Module implementation is typed by the call it wraps",
        arguments: [YieldModuleUpgradeCalldata.v3Implementation, YieldModuleUpgradeCalldata.polygonV2Implementation]
    )
    func knownImplementationIsUnwrapped(implementation: String) {
        let calldata = YieldModuleUpgradeCalldata.wrapping(yieldSend, implementation: implementation)

        #expect(YieldModuleUpgradeHistoryMapper.innerMethodId(calldata: calldata, blockchain: polygon) == YieldModuleUpgradeCalldata.yieldSendMethodId)
    }

    @Test("An upgrade to an implementation the app doesn't know is left as it is")
    func unknownImplementationIsNotUnwrapped() {
        let calldata = YieldModuleUpgradeCalldata.wrapping(yieldSend, implementation: YieldModuleUpgradeCalldata.unknownImplementation)

        #expect(YieldModuleUpgradeHistoryMapper.innerMethodId(calldata: calldata, blockchain: polygon) == nil)
    }

    @Test("An implementation known only on another network is left as it is")
    func implementationOfAnotherNetworkIsNotUnwrapped() {
        let calldata = YieldModuleUpgradeCalldata.wrapping(yieldSend, implementation: YieldModuleUpgradeCalldata.polygonV1Implementation)

        #expect(YieldModuleUpgradeHistoryMapper.innerMethodId(calldata: calldata, blockchain: .bsc(testnet: false)) == nil)
    }

    @Test(
        "Calldata that is not a well-formed upgrade is left as it is, however it points past its end",
        arguments: [
            "deprecated",
            YieldModuleUpgradeCalldata.upgradeHead(implementation: YieldModuleUpgradeCalldata.v3Implementation, offset: 0x1000, length: 0),
            YieldModuleUpgradeCalldata.upgradeHead(implementation: YieldModuleUpgradeCalldata.v3Implementation, offset: 0x40, length: 0x1000),
        ]
    )
    func malformedCalldataIsNotUnwrapped(calldata: String) {
        #expect(YieldModuleUpgradeHistoryMapper.innerMethodId(calldata: calldata, blockchain: polygon) == nil)
    }

    @Test(
        "The Etherscan history types a token row by the call inside only for an upgrade to a known implementation",
        arguments: zip(
            [YieldModuleUpgradeCalldata.v3Implementation, YieldModuleUpgradeCalldata.unknownImplementation],
            [YieldModuleUpgradeCalldata.yieldSendMethodId, UpgradeToAndCallMethod.methodId]
        )
    )
    func etherscanTokenRowIsTypedByTheInnerCallOfAKnownUpgrade(implementation: String, expectedMethodId: String) throws {
        let calldata = YieldModuleUpgradeCalldata.wrapping(yieldSend, implementation: implementation)

        let records = try mapEtherscanTokenRow(input: calldata)

        #expect(records.map(\.type) == [.contractMethodIdentifier(id: expectedMethodId)])
    }

    @Test(
        "The BlockBook history types a transaction by the call inside only for an upgrade to a known implementation",
        arguments: zip(
            [YieldModuleUpgradeCalldata.v3Implementation, YieldModuleUpgradeCalldata.unknownImplementation],
            [YieldModuleUpgradeCalldata.yieldSendMethodId, UpgradeToAndCallMethod.methodId]
        )
    )
    func blockBookTransactionIsTypedByTheInnerCallOfAKnownUpgrade(implementation: String, expectedMethodId: String) throws {
        let calldata = YieldModuleUpgradeCalldata.wrapping(yieldSend, implementation: implementation)

        let records = try mapBlockBookTransaction(calldata: calldata)

        #expect(records.map(\.type) == [.contractMethodIdentifier(id: expectedMethodId)])
    }
}

// MARK: - Helpers

private extension YieldModuleUpgradeHistoryMapperTests {
    func mapEtherscanTokenRow(input: String) throws -> [TransactionRecord] {
        let response = EtherscanTransactionHistoryResult(
            status: "1",
            message: nil,
            result: .transactions([
                .init(
                    confirmations: "10",
                    contractAddress: usdc.contractAddress,
                    from: walletAddress,
                    functionName: "upgradeToAndCall(address newImplementation, bytes data)",
                    methodId: UpgradeToAndCallMethod.methodId,
                    gasPrice: "30000000000",
                    gasUsed: "396754",
                    hash: "0xdeadbeef",
                    input: input,
                    isError: "0",
                    timeStamp: "1700000000",
                    to: recipient,
                    txReceiptStatus: "1",
                    value: "400000"
                ),
            ])
        )

        return try EtherscanTransactionHistoryMapper(blockchain: polygon)
            .mapToTransactionRecords(response, walletAddress: walletAddress, amountType: .token(value: usdc))
    }

    func mapBlockBookTransaction(calldata: String) throws -> [TransactionRecord] {
        let blockchain = Blockchain.ethereum(testnet: false)
        let response = BlockBookAddressResponse(
            page: 1,
            totalPages: 1,
            itemsOnPage: 25,
            address: walletAddress,
            balance: "0",
            unconfirmedBalance: nil,
            unconfirmedTxs: nil,
            txs: 1,
            nonTokenTxs: nil,
            transactions: [.init(from: walletAddress, to: moduleAddress, calldata: calldata)],
            tokens: nil
        )

        return try EthereumTransactionHistoryMapper(blockchain: blockchain)
            .mapToTransactionRecords(response, walletAddress: walletAddress, amountType: .coin)
    }
}

// MARK: - Test fixtures

private extension BlockBookAddressResponse.Transaction {
    init(from: String, to: String, calldata: String) {
        self.init(
            txid: "0xdeadbeef",
            contractType: nil,
            contractName: nil,
            version: nil,
            vin: [.init(address: from)],
            vout: [.init(address: to)],
            blockHash: nil,
            blockHeight: 1,
            confirmations: 1,
            blockTime: 1_700_000_000,
            value: "0",
            valueIn: nil,
            fees: "210000",
            hex: nil,
            tokenTransfers: nil,
            ethereumSpecific: .init(status: .ok, nonce: 1, gasLimit: nil, gasUsed: nil, gasPrice: nil, data: calldata, parsedData: nil),
            chainExtraData: nil,
            tronTXReceipt: nil,
            fromAddress: nil,
            toAddress: nil,
            voteList: nil
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
        self.init(value: "0", n: 0, hex: nil, addresses: [address], isAddress: true, spent: nil, isOwn: nil)
    }
}
