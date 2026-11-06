//
//  JointOperationFormVerifierTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import Testing
import BlockchainSdk
@testable import Tangem

@Suite("Tests for verifying the form of a joint account's operation before signing")
struct JointOperationFormVerifierTests {
    private let verifier = JointOperationFormVerifier()

    // MARK: - Allowed

    @Test("A coin transfer to someone other than the Safe is allowed")
    func coinTransferIsAllowed() throws {
        let transaction = Self.safeTransaction(to: Constants.recipient, value: 1, data: Data())

        try verifier.verify(safeTransaction: transaction, safeAddress: Constants.safeAddress)
    }

    @Test("A token transfer whose contract is not the Safe is allowed")
    func tokenTransferIsAllowed() throws {
        let data = try TransferERC20TokenMethod(destination: Constants.recipient, amount: 5).data
        let transaction = Self.safeTransaction(to: Constants.contract, value: 0, data: data)

        try verifier.verify(safeTransaction: transaction, safeAddress: Constants.safeAddress)
    }

    // MARK: - Refused

    @Test("A coin transfer aimed at the Safe itself is refused")
    func coinTransferToTheSafeIsRefused() {
        let transaction = Self.safeTransaction(to: Constants.safeAddress, value: 1, data: Data())

        #expect(throws: JointOperationError.unsupportedOperationForm) {
            try verifier.verify(safeTransaction: transaction, safeAddress: Constants.safeAddress)
        }
    }

    @Test("The Safe is matched without regard to case")
    func theSafeIsMatchedCaseInsensitively() {
        let transaction = Self.safeTransaction(to: Constants.safeAddress.uppercased(), value: 1, data: Data())

        #expect(throws: JointOperationError.unsupportedOperationForm) {
            try verifier.verify(safeTransaction: transaction, safeAddress: Constants.safeAddress)
        }
    }

    @Test("A token transfer whose contract is the Safe is refused")
    func tokenTransferOnTheSafeIsRefused() throws {
        let data = try TransferERC20TokenMethod(destination: Constants.recipient, amount: 5).data
        let transaction = Self.safeTransaction(to: Constants.safeAddress, value: 0, data: data)

        #expect(throws: JointOperationError.unsupportedOperationForm) {
            try verifier.verify(safeTransaction: transaction, safeAddress: Constants.safeAddress)
        }
    }

    @Test("A delegatecall is refused")
    func delegatecallIsRefused() {
        let transaction = Self.safeTransaction(to: Constants.recipient, value: 1, data: Data(), operation: 1)

        #expect(throws: JointOperationError.unsupportedOperationForm) {
            try verifier.verify(safeTransaction: transaction, safeAddress: Constants.safeAddress)
        }
    }

    @Test("A call of a method other than transfer is refused")
    func anotherMethodIsRefused() {
        let data = ApproveERC20TokenMethod(spender: Constants.recipient, amount: 5).data
        let transaction = Self.safeTransaction(to: Constants.contract, value: 0, data: data)

        #expect(throws: JointOperationError.unsupportedOperationForm) {
            try verifier.verify(safeTransaction: transaction, safeAddress: Constants.safeAddress)
        }
    }

    @Test("A value sent alongside a token call is refused")
    func valueWithCalldataIsRefused() throws {
        let data = try TransferERC20TokenMethod(destination: Constants.recipient, amount: 5).data
        let transaction = Self.safeTransaction(to: Constants.contract, value: 1, data: data)

        #expect(throws: JointOperationError.unsupportedOperationForm) {
            try verifier.verify(safeTransaction: transaction, safeAddress: Constants.safeAddress)
        }
    }

    @Test("A call with neither a value nor data is refused")
    func emptyCallIsRefused() {
        let transaction = Self.safeTransaction(to: Constants.recipient, value: 0, data: Data())

        #expect(throws: JointOperationError.unsupportedOperationForm) {
            try verifier.verify(safeTransaction: transaction, safeAddress: Constants.safeAddress)
        }
    }
}

// MARK: - Fixtures

private extension JointOperationFormVerifierTests {
    static func safeTransaction(to: String, value: BigUInt, data: Data, operation: Int = 0) -> SafeTransaction {
        SafeTransaction(
            to: to,
            value: value,
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

private extension JointOperationFormVerifierTests {
    enum Constants {
        static let safeAddress = "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b"
        static let recipient = "0x2b5ad9c1e7f40638b2c1a9d3e5f70241c6b8a91c"
        static let contract = "0xdac17f958d2ee523a2206206994597c13d831ec7"
    }
}
