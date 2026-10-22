//
//  CommonJointOperationBlockaidGateTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
import ReownWalletKit
@testable import Tangem

// MARK: - Tests

@Suite("Tests for the Blockaid check a joint operation goes through before a co-signer signs it")
struct CommonJointOperationBlockaidGateTests {
    @Test("Blockaid's verdict on the operation is what the gate reports", arguments: [
        ("Malicious", JointOperationBlockaidVerdict.malicious),
        ("Benign", .safe),
        ("Warning", .safe),
        ("Info", .safe),
        ("Error", .unknown),
    ])
    func verdictFollowsTheResultType(resultType: String, expected: JointOperationBlockaidVerdict) async throws {
        let service = BlockaidAPIServiceStub(response: try Self.response(validation: #"{"status": "Success", "result_type": "\#(resultType)"}"#))

        #expect(await verdict(with: service) == expected)
    }

    @Test("A scan that could not simulate a Safe not yet deployed is read, and gives no verdict")
    func undeployedSafeScanGivesNoVerdict() async throws {
        let json = #"""
        {"validation":{"status":"Error","result_type":"Error","error":"Simulation Error: Failed to get safe owners","description":"","reason":"","features":[]},"simulation":{"status":"Error","error":"Failed to get safe owners","params":{"block_tag":"latest","chain":"ethereum"},"address_details":{}},"block":"95115494","chain":"polygon","account_address":"0xAA0066cC6D0fd2d108296F5B87aA03824737661c"}
        """#
        let service = BlockaidAPIServiceStub(response: try Self.response(json: json))

        #expect(await verdict(with: service) == .unknown)
    }

    @Test("A validation that did not succeed gives no verdict")
    func failedValidationIsUnknown() async throws {
        let service = BlockaidAPIServiceStub(response: try Self.response(validation: #"{"status": "Error", "result_type": "Benign"}"#))

        #expect(await verdict(with: service) == .unknown)
    }

    @Test("A response with no validation gives no verdict")
    func missingValidationIsUnknown() async throws {
        let service = BlockaidAPIServiceStub(response: try Self.response(validation: nil))

        #expect(await verdict(with: service) == .unknown)
    }

    @Test("A Blockaid that can't be reached is reported as such")
    func failedRequestIsUnavailable() async {
        let service = BlockaidAPIServiceStub(response: nil)

        #expect(await verdict(with: service) == .unavailable)
    }

    @Test("A co-signer whose own address can't be derived is not vouched for")
    func missingOwnerIsUnavailable() async throws {
        let service = BlockaidAPIServiceStub(response: try Self.response(validation: nil))

        let verdict = await CommonJointOperationBlockaidGate(apiService: service).verdict(
            on: Self.operation(),
            safeAddress: Constants.safeAddress,
            ownerAddress: nil,
            blockchain: .polygon(testnet: false)
        )

        #expect(verdict == .unavailable)
        #expect(service.requests.isEmpty)
    }

    @Test("A network Blockaid does not cover is not asked about")
    func unsupportedNetworkIsNotScanned() async throws {
        let service = BlockaidAPIServiceStub(response: try Self.response(validation: nil))

        let verdict = await verdict(with: service, blockchain: .polygon(testnet: true))

        #expect(verdict == .unknown)
        #expect(service.requests.isEmpty)
    }

    @Test("Blockaid is asked about the very message the co-signer signs, on the owner's behalf")
    func requestCarriesTheSignedMessage() async throws {
        let service = BlockaidAPIServiceStub(response: try Self.response(validation: nil))
        let operation = Self.operation()

        _ = await verdict(with: service, operation: operation)

        let request = try #require(service.requests.first)
        let params = try request.params.map { try JSONDecoder().decode(String.self, from: JSONEncoder().encode($0)) }
        let typedData = try JSONDecoder().decode(EIP712TypedData.self, from: Data(try #require(params.last).utf8))

        #expect(request.method == "eth_signTypedData_v4")
        #expect(request.address == Constants.owner)
        #expect(params.first == Constants.owner)
        #expect(typedData.signHash == operation.safeTransaction.signHash(chainId: Constants.chainId, safeAddress: Constants.safeAddress))
    }
}

// MARK: - Helpers

private extension CommonJointOperationBlockaidGateTests {
    func verdict(
        with service: BlockaidAPIServiceStub,
        operation: JointAccountOperation = Self.operation(),
        blockchain: BlockchainSdk.Blockchain = .polygon(testnet: false)
    ) async -> JointOperationBlockaidVerdict {
        await CommonJointOperationBlockaidGate(apiService: service).verdict(
            on: operation,
            safeAddress: Constants.safeAddress,
            ownerAddress: Constants.owner,
            blockchain: blockchain
        )
    }

    static func response(validation: String?) throws -> BlockaidDTO.EvmScan.Response {
        let validationField = validation.map { #", "validation": \#($0)"# } ?? ""

        return try response(json: #"{"chain": "polygon"\#(validationField)}"#)
    }

    static func response(json: String) throws -> BlockaidDTO.EvmScan.Response {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        return try decoder.decode(BlockaidDTO.EvmScan.Response.self, from: Data(json.utf8))
    }

    static func operation() -> JointAccountOperation {
        let feeParameters = SafeTransactionFeeParameters(
            safeTxGas: 23520,
            baseGas: 110_000,
            gasPrice: 1_575_000_000,
            gasToken: .coin(.polygon(testnet: false)),
            refundReceiver: Constants.owner,
            isDeployed: true
        )

        return JointAccountOperation(
            id: "op",
            chainId: Constants.chainId,
            safeTransaction: SafeTransaction(
                innerCall: SafeInnerCall(to: Constants.recipient, value: 1_000_000_000_000_000, data: Data()),
                feeParameters: feeParameters,
                nonce: 3
            ),
            status: .awaitingSignatures,
            txHash: nil,
            initiator: Constants.recipient,
            signatures: []
        )
    }
}

// MARK: - Constants

private extension CommonJointOperationBlockaidGateTests {
    enum Constants {
        static let chainId = 137
        static let safeAddress = "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b"
        static let owner = "0x7e5fb2c1a9d3e5f70241c6b8a91cd9c1e7f45bdf"
        static let recipient = "0x2b5ad9c1e7f40638b2c1a9d3e5f70241c6b8a91c"
    }
}

// MARK: - Doubles

private final class BlockaidAPIServiceStub: BlockaidAPIService {
    struct Request {
        let address: String?
        let method: String
        let params: [AnyCodable]
    }

    private(set) var requests: [Request] = []

    private let response: BlockaidDTO.EvmScan.Response?

    init(response: BlockaidDTO.EvmScan.Response?) {
        self.response = response
    }

    func scanEvm(
        address: String?,
        blockchain: BlockchainSdk.Blockchain,
        method: String,
        params: [AnyCodable],
        domain: URL
    ) async throws -> BlockaidDTO.EvmScan.Response {
        requests.append(Request(address: address, method: method, params: params))

        guard let response else {
            throw URLError(.notConnectedToInternet)
        }

        return response
    }

    func scanSite(url: URL) async throws -> BlockaidDTO.SiteScan.Response {
        throw URLError(.unsupportedURL)
    }

    func scanSolana(address: String, method: String, transactions: [String], domain: URL) async throws -> BlockaidDTO.SolanaScan.Response {
        throw URLError(.unsupportedURL)
    }

    func scanEvmTransactionBulk(
        blockchain: BlockchainSdk.Blockchain,
        transactions: [BlockaidDTO.TransactionParams]
    ) async throws -> BlockaidDTO.EvmTransactionBulkScan.Response {
        throw URLError(.unsupportedURL)
    }
}
