//
//  WCEthTypedDataValidatorTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
@testable import Tangem

@Suite("Tests for `WCEthTypedDataValidator`")
struct WCEthTypedDataValidatorTests {
    private typealias Fixture = WCEthTypedDataFixture
    private typealias ValidationError = WCEthTypedDataValidator.ValidationError

    private let validator = WCEthTypedDataValidator()

    @Test("Rejects the gasless executor batch authorization from the bug bounty report")
    func rejectsReportedBatchPayload() throws {
        let typedData = try Fixture.decode(Fixture.reportedBatchPayload)

        #expect(throws: ValidationError.gaslessPrimaryType) {
            try validator.validate(typedData, signerAddress: Fixture.signer)
        }
    }

    @Test("Rejects a gasless primary type under any domain", arguments: [
        "GaslessTransaction",
        "GaslessBatchTransaction",
        "gaslesstransaction",
        " GaslessBatchTransaction ",
    ])
    func rejectsGaslessPrimaryType(primaryType: String) throws {
        let typedData = try Fixture.decode(Fixture.permitPayload(primaryType: primaryType))

        #expect(throws: ValidationError.gaslessPrimaryType) {
            try validator.validate(typedData, signerAddress: Fixture.signer)
        }
    }

    @Test("Rejects the executor domain name", arguments: [
        "Tangem7702GaslessExecutor",
        " tangem7702gaslessexecutor ",
    ])
    func rejectsExecutorDomainName(domainName: String) throws {
        let typedData = try Fixture.decode(Fixture.permitPayload(domain: Fixture.permitDomain(name: domainName)))

        #expect(throws: ValidationError.gaslessExecutorDomain) {
            try validator.validate(typedData, signerAddress: Fixture.signer)
        }
    }

    @Test("Rejects the signer as verifyingContract in any spelling", arguments: [
        "0x54f6ab13abA6c169A3E6294B7e9Ac6A02F470aab",
        "0x54f6ab13aba6c169a3e6294b7e9ac6a02f470aab",
        "0X54F6AB13ABA6C169A3E6294B7E9AC6A02F470AAB",
        "54f6ab13abA6c169A3E6294B7e9Ac6A02F470aab",
        " 0x54f6ab13abA6c169A3E6294B7e9Ac6A02F470aab ",
    ])
    func rejectsSignerAsVerifyingContract(verifyingContract: String) throws {
        let typedData = try Fixture.decode(Fixture.permitPayload(domain: Fixture.permitDomain(verifyingContract: verifyingContract)))

        #expect(throws: ValidationError.signerIsVerifyingContract) {
            try validator.validate(typedData, signerAddress: Fixture.signer)
        }
    }

    @Test("Rejects a verifyingContract that is not a string")
    func rejectsNonStringVerifyingContract() throws {
        let domain = #"{"name":"USD Coin","version":"2","chainId":1,"verifyingContract":123}"#
        let typedData = try Fixture.decode(Fixture.permitPayload(domain: domain))

        #expect(throws: ValidationError.malformedPayload) {
            try validator.validate(typedData, signerAddress: Fixture.signer)
        }
    }

    @Test("Rejects a domain that is not an object")
    func rejectsNonObjectDomain() throws {
        let typedData = try Fixture.decode(Fixture.permitPayload(domain: "[]"))

        #expect(throws: ValidationError.malformedPayload) {
            try validator.validate(typedData, signerAddress: Fixture.signer)
        }
    }

    @Test("Allows a regular Permit")
    func allowsPermit() throws {
        let typedData = try Fixture.decode(Fixture.permitPayload())

        #expect(throws: Never.self) {
            try validator.validate(typedData, signerAddress: Fixture.signer)
        }
    }

    @Test("Allows a domain without verifyingContract", arguments: [
        #"{"name":"USD Coin","version":"2","chainId":1}"#,
        #"{"name":"USD Coin","version":"2","chainId":1,"verifyingContract":null}"#,
        "null",
    ])
    func allowsDomainWithoutVerifyingContract(domain: String) throws {
        let typedData = try Fixture.decode(Fixture.permitPayload(domain: domain))

        #expect(throws: Never.self) {
            try validator.validate(typedData, signerAddress: Fixture.signer)
        }
    }

    @Test("Rejects the app's own gasless typed data for any signer")
    func rejectsOwnGaslessTypedData() throws {
        let util = GaslessTransactionBuilder.GaslessTransactionsEIP712Util()
        let transaction = GaslessTransactionsDTO.Request.GaslessTransaction.TransactionData.Transaction(
            to: Fixture.usdcContract,
            value: "0",
            gasLimit: "50000",
            data: "0x"
        )
        let fee = GaslessTransactionsDTO.Request.GaslessTransaction.TransactionData.Fee(
            feeToken: Fixture.zeroAddress,
            maxTokenFee: "0",
            coinPriceInToken: "0",
            feeTransferGasLimit: "0",
            baseGas: "0",
            feeReceiver: Fixture.zeroAddress
        )

        let single = try util.makeGaslessTypedData(
            transaction: transaction,
            fee: fee,
            nonce: "0",
            chainId: 1,
            verifyingContract: Fixture.signer,
            executorVersion: .batchCapable
        )
        let batch = util.makeGaslessBatchTypedData(
            transactions: [transaction],
            fee: fee,
            nonce: "1",
            chainId: 1,
            verifyingContract: Fixture.signer
        )

        for typedData in [single, batch] {
            for signerAddress in [Fixture.signer, Fixture.usdcContract] {
                #expect(throws: ValidationError.gaslessPrimaryType) {
                    try validator.validate(typedData, signerAddress: signerAddress)
                }
            }
        }
    }
}
