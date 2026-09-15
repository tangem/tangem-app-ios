//
//  SafeInnerCallParserTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
@testable import BlockchainSdk
import Testing

struct SafeInnerCallParserTests {
    @Test("A call with a value and no data is a transfer of the coin")
    func coinTransfer() throws {
        let call = SafeInnerCall(to: Constants.recipient, value: 10, data: Data())

        #expect(try SafeInnerCallTypeParser.parse(call) == .transfer(.coin(destination: Constants.recipient, value: 10)))
    }

    @Test("A transfer call on a contract with no value is a transfer of its token")
    func tokenTransfer() throws {
        let data = try TransferERC20TokenMethod(destination: Constants.recipient, amount: 5).data
        let call = SafeInnerCall(to: Constants.contract, value: 0, data: data)

        #expect(try SafeInnerCallTypeParser.parse(call) == .transfer(.token(contractAddress: Constants.contract, destination: Constants.recipient, value: 5)))
    }

    @Test("A transfer call that carries a value as well is not a transfer")
    func tokenTransferWithValueIsRefused() throws {
        let data = try TransferERC20TokenMethod(destination: Constants.recipient, amount: 5).data
        let call = SafeInnerCall(to: Constants.contract, value: 1, data: data)

        #expect(throws: SafeInnerCallTypeParser.Error.valueWithCalldata) {
            try SafeInnerCallTypeParser.parse(call)
        }
    }

    @Test("A call with neither a value nor data is not a transfer")
    func emptyCallIsRefused() {
        let call = SafeInnerCall(to: Constants.recipient, value: 0, data: Data())

        #expect(throws: SafeInnerCallTypeParser.Error.emptyCall) {
            try SafeInnerCallTypeParser.parse(call)
        }
    }

    @Test("A value sent along with calldata is not a transfer")
    func valueWithCalldataIsRefused() {
        let call = SafeInnerCall(to: Constants.recipient, value: 10, data: Data([0x01]))

        #expect(throws: SafeInnerCallTypeParser.Error.valueWithCalldata) {
            try SafeInnerCallTypeParser.parse(call)
        }
    }

    @Test("Calldata of another method is not a transfer")
    func otherMethodIsRefused() {
        let data = ApproveERC20TokenMethod(spender: Constants.recipient, amount: 5).data
        let call = SafeInnerCall(to: Constants.contract, value: 0, data: data)

        #expect(throws: SafeInnerCallTypeParser.Error.unsupportedCalldata) {
            try SafeInnerCallTypeParser.parse(call)
        }
    }

    @Test("A truncated transfer call is not a transfer")
    func truncatedTransferIsRefused() throws {
        let data = try TransferERC20TokenMethod(destination: Constants.recipient, amount: 5).data.dropLast()
        let call = SafeInnerCall(to: Constants.contract, value: 0, data: data)

        #expect(throws: SafeInnerCallTypeParser.Error.unsupportedCalldata) {
            try SafeInnerCallTypeParser.parse(call)
        }
    }

    @Test("The Safe transaction hands its inner call out apart from the gas terms")
    func safeTransactionInnerCall() throws {
        let data = try TransferERC20TokenMethod(destination: Constants.recipient, amount: 5).data
        let transaction = Self.transaction(data: data, operation: 0)

        #expect(try transaction.innerCall == SafeInnerCall(to: Constants.contract, value: 0, data: data))
        #expect(try SafeInnerCallTypeParser.parse(transaction.innerCall) == .transfer(.token(contractAddress: Constants.contract, destination: Constants.recipient, value: 5)))
    }

    @Test("A Safe transaction that is not a call hands out no inner call")
    func safeTransactionDelegateCallIsRefused() throws {
        let data = try TransferERC20TokenMethod(destination: Constants.recipient, amount: 5).data
        let transaction = Self.transaction(data: data, operation: 1)

        #expect(throws: SafeTransaction.Error.unsupportedOperation) {
            try transaction.innerCall
        }
    }
}

// MARK: - Fixtures

private extension SafeInnerCallParserTests {
    static func transaction(data: Data, operation: Int) -> SafeTransaction {
        SafeTransaction(
            to: Constants.contract,
            value: 0,
            data: data,
            operation: operation,
            safeTxGas: 23_520,
            baseGas: 110_000,
            gasPrice: 1_500_000_000,
            gasToken: "0x0000000000000000000000000000000000000000",
            refundReceiver: "0x0000000000000000000000000000000000000000",
            nonce: 7
        )
    }
}

// MARK: - Constants

private extension SafeInnerCallParserTests {
    enum Constants {
        static let recipient = "0x2b5ad9c1e7f40638b2c1a9d3e5f70241c6b8a91c"
        static let contract = "0xdac17f958d2ee523a2206206994597c13d831ec7"
    }
}
