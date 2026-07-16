//
//  AllowanceCheckerTests.swift
//  BlockchainSdkTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Testing
import BigInt
import TangemFoundation
@testable import BlockchainSdk

struct AllowanceCheckerTests {
    private let token = Token(name: "USDC", symbol: "USDC", contractAddress: "0xUSDCContract", decimalCount: 6)
    private let approveCalldata = Data([0x09, 0x5e, 0xa7, 0xb3])

    private var anySpender: String { "0xSpender" }
    private var anyOwner: String { "0xOwner" }

    /// `.specified` must encode exactly the requested amount scaled to the token's decimals — never the raw amount, never more.
    @Test("makeApproveData(.specified) encodes the requested amount scaled to token decimals")
    func makeApproveData_specified_encodesScaledAmount() throws {
        let (sut, builder) = makeSUT()

        let result = try sut.makeApproveData(spender: anySpender, amount: 100, policy: .specified)

        #expect(builder.buildForApproveCalls.count == 1)
        let call = try #require(builder.buildForApproveCalls.first)
        #expect(call.spender == anySpender)
        #expect(call.amount == Decimal(100) * token.decimalValue)

        #expect(result.spender == anySpender)
        #expect(result.toContractAddress == token.contractAddress)
        #expect(result.txData == approveCalldata)
    }

    /// `.unlimited` must encode the maximum value and never the requested amount — the guard against accidentally granting an allowance that doesn't match the user's choice.
    @Test("makeApproveData(.unlimited) encodes the maximum amount, not the requested one")
    func makeApproveData_unlimited_encodesMaxAmount() throws {
        let (sut, builder) = makeSUT()

        let result = try sut.makeApproveData(spender: anySpender, amount: 100, policy: .unlimited)

        #expect(builder.buildForApproveCalls.count == 1)
        let call = try #require(builder.buildForApproveCalls.first)
        #expect(call.amount == .greatestFiniteMagnitude)
        #expect(call.amount != Decimal(100) * token.decimalValue)

        #expect(result.spender == anySpender)
        #expect(result.toContractAddress == token.contractAddress)
    }
}

// MARK: - Helpers

private extension AllowanceCheckerTests {
    func makeSUT() -> (sut: AllowanceChecker, builder: EthereumTransactionDataBuilderSpy) {
        let builder = EthereumTransactionDataBuilderSpy(approveData: approveCalldata)
        let sut = AllowanceChecker(
            blockchain: .ethereum(testnet: false),
            amountType: .token(value: token),
            walletAddress: anyOwner,
            ethereumNetworkProvider: EthereumNetworkProviderStub(),
            ethereumTransactionDataBuilder: builder
        )
        return (sut, builder)
    }
}

// MARK: - Doubles

private final class EthereumTransactionDataBuilderSpy: EthereumTransactionDataBuilder {
    let approveData: Data
    private(set) var buildForApproveCalls: [(spender: String, amount: Decimal)] = []

    init(approveData: Data) {
        self.approveData = approveData
    }

    func buildForTokenTransfer(destination: String, amount: Amount) throws -> Data {
        Data()
    }

    func buildForApprove(spender: String, amount: Decimal) throws -> Data {
        buildForApproveCalls.append((spender: spender, amount: amount))
        return approveData
    }

    func buildTransactionPayload(transaction: Transaction) async throws -> TransactionPayload {
        throw AllowanceCheckerTestsError.notImplemented
    }
}

private struct EthereumNetworkProviderStub: EthereumNetworkProvider {
    func getFee(destination: String, value: String?, data: Data?, stateOverride: EthereumStateOverride?) -> AnyPublisher<[Fee], Error> {
        .empty
    }

    func getGasPrice() -> AnyPublisher<BigUInt, Error> { .empty }
    func getGasLimit(to: String, from: String, value: String?, data: String?) -> AnyPublisher<BigUInt, Error> { .empty }
    func getFeeHistory() -> AnyPublisher<EthereumFeeHistory, Error> { .empty }
    func getAllowance(owner: String, spender: String, contractAddress: String) -> AnyPublisher<Decimal, Error> { .empty }
    func getAllowanceRaw(owner: String, spender: String, contractAddress: String) -> AnyPublisher<String, Error> { .empty }
    func getBalance(_ address: String) -> AnyPublisher<Decimal, Error> { .empty }
    func getTxCount(_ address: String) -> AnyPublisher<Int, Error> { .empty }
    func getPendingTxCount(_ address: String) -> AnyPublisher<Int, Error> { .empty }
    func getSmartContractNonce(for address: String) -> AnyPublisher<Int, Error> { .empty }
}

private enum AllowanceCheckerTestsError: Error {
    case notImplemented
}
