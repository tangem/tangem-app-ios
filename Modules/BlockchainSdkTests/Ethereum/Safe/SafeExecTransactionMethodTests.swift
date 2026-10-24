//
//  SafeExecTransactionMethodTests.swift
//  BlockchainSdkTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
@testable import BlockchainSdk
import Testing

struct SafeExecTransactionMethodTests {
    private let recipient = "0xc5817772d0fcb93e0c8d855724b2cd2ad58a8aed"
    private let tokenContract = "0xdac17f958d2ee523a2206206994597c13d831ec7"
    private let oneEther: BigUInt = 1_000_000_000_000_000_000

    @Test("Decodes the inner call, the operation and the refund cap")
    func decodesExecTransaction() throws {
        let calldata = SafeExecTransactionCalldata.make(to: recipient, value: oneEther)
        let method = try #require(SafeExecTransactionMethod(calldata: calldata))

        #expect(method.innerCall == SafeInnerCall(to: recipient, value: oneEther, data: Data()))
        #expect(method.operation == .call)
        #expect(method.gasToken == SafeGasToken.coinGasTokenRawValue)
        #expect(method.refundCap == SafeExecTransactionCalldata.refundCap)
    }

    @Test("Decodes the calldata of the inner call")
    func decodesInnerCalldata() throws {
        let transfer = try TransferERC20TokenMethod(destination: recipient, amount: 17_984_408).data
        let calldata = SafeExecTransactionCalldata.make(to: tokenContract, value: 0, data: transfer)
        let method = try #require(SafeExecTransactionMethod(calldata: calldata))

        #expect(method.innerCall.data == transfer)
    }

    @Test("Decodes a delegatecall")
    func decodesDelegateCall() throws {
        let calldata = SafeExecTransactionCalldata.make(to: recipient, value: 0, operation: 1)

        #expect(try #require(SafeExecTransactionMethod(calldata: calldata)).operation == .delegateCall)
    }

    @Test("Rejects truncated calldata, an unknown operation and other methods")
    func rejectsMalformedCalldata() {
        let calldata = SafeExecTransactionCalldata.make(to: recipient, value: oneEther)

        #expect(SafeExecTransactionMethod(calldata: String(calldata.prefix(400))) == nil)
        #expect(SafeExecTransactionMethod(calldata: SafeExecTransactionCalldata.make(to: recipient, value: 0, operation: 2)) == nil)
        #expect(SafeExecTransactionMethod(calldata: TransferERC20TokenMethod.methodId + calldata.dropFirst(10)) == nil)
    }
}
