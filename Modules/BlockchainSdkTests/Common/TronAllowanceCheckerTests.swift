//
//  TronAllowanceCheckerTests.swift
//  BlockchainSdkTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Testing
@testable import BlockchainSdk

struct TronAllowanceCheckerTests {
    private let token = Token(name: "Tether", symbol: "USDT", contractAddress: "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t", decimalCount: 6)
    private let approveSelector = Data([0x09, 0x5E, 0xA7, 0xB3])

    private var anySpender: String { "TXXxc9NsHndfQ2z9kMKyWpYa5T3QbhKGwn" }
    private var anyOwner: String { "TU1BRXbr6EmKmrLL4Kymv7Wp18eYFkRfAF" }

    /// The provider returns the allowance in raw token units.
    @Test(
        "allowanceState normalizes the raw allowance by token decimals",
        arguments: [
            (rawAllowance: Decimal(100_000_000), amount: Decimal(100), enough: true),
            (rawAllowance: Decimal(100_000_000), amount: Decimal(string: "100.000001")!, enough: false),
            (rawAllowance: .zero, amount: Decimal(100), enough: false),
        ]
    )
    func allowanceState_normalizesRawAllowance(rawAllowance: Decimal, amount: Decimal, enough: Bool) async throws {
        let sut = makeSUT(rawAllowance: rawAllowance)

        let result = try await sut.allowanceState(amount: amount, spender: anySpender, policy: .specified)

        switch result {
        case .enoughAllowance:
            #expect(enough)
        case .approveRequired:
            #expect(!enough)
        case .revokeAndApproveRequired:
            Issue.record("TRC20 approve must never require a revoke")
        }
    }

    /// TRC20 has no reset-to-zero restriction — a partial allowance must not trigger the revoke flow.
    @Test("partial existing allowance produces a plain approve, not revoke-and-approve")
    func allowanceState_partialAllowance_neverRequiresRevoke() async throws {
        let sut = makeSUT(rawAllowance: 50_000_000)

        let result = try await sut.allowanceState(amount: 100, spender: anySpender, policy: .specified)

        guard case .approveRequired(let data) = result else {
            Issue.record("Expected .approveRequired, got \(result)")
            return
        }
        #expect(data.spender == anySpender)
        #expect(data.toContractAddress == token.contractAddress)
    }

    @Test("makeApproveData(.specified) builds full approve calldata with the scaled amount")
    func makeApproveData_specified_buildsFullCalldata() throws {
        let sut = makeSUT(rawAllowance: .zero)

        let data = try sut.makeApproveData(spender: anySpender, amount: 100, policy: .specified)

        #expect(data.txData.count == 68)
        #expect(data.txData.prefix(4) == approveSelector)

        let expectedSpender = try TronUtils().convertAddressToBytesPadded(anySpender)
        #expect(data.txData[4 ..< 36] == expectedSpender)

        // 100 USDT with 6 decimals = 100_000_000 = 0x05F5E100
        let expectedAmount = Data(repeating: 0, count: 28) + Data([0x05, 0xF5, 0xE1, 0x00])
        #expect(data.txData[36 ..< 68] == expectedAmount)

        #expect(data.spender == anySpender)
        #expect(data.toContractAddress == token.contractAddress)
    }

    /// `.unlimited` must encode the maximum uint256 — the requested amount must not leak into the calldata.
    @Test("makeApproveData(.unlimited) encodes max uint256")
    func makeApproveData_unlimited_encodesMaxUint256() throws {
        let sut = makeSUT(rawAllowance: .zero)

        let data = try sut.makeApproveData(spender: anySpender, amount: 100, policy: .unlimited)

        #expect(data.txData.count == 68)
        #expect(data.txData.prefix(4) == approveSelector)
        #expect(data.txData[36 ..< 68] == Data(repeating: 0xFF, count: 32))
    }

    @Test("coin amount type is rejected")
    func makeApproveData_coinAmountType_throws() {
        let sut = makeCoinSUT()

        #expect(throws: AllowanceCheckerError.contractAddressNotFound) {
            try sut.makeApproveData(spender: anySpender, amount: 100, policy: .specified)
        }
    }

    @Test("allowanceState rejects a coin amount type as well")
    func allowanceState_coinAmountType_throws() async {
        let sut = makeCoinSUT()

        await #expect(throws: AllowanceCheckerError.contractAddressNotFound) {
            _ = try await sut.allowanceState(amount: 100, spender: anySpender, policy: .specified)
        }
    }

    @Test("allowanceState(.unlimited) returns unlimited approve data")
    func allowanceState_unlimitedPolicy_returnsUnlimitedApproveData() async throws {
        let sut = makeSUT(rawAllowance: .zero)

        let result = try await sut.allowanceState(amount: 100, spender: anySpender, policy: .unlimited)

        guard case .approveRequired(let data) = result else {
            Issue.record("Expected .approveRequired, got \(result)")
            return
        }
        #expect(data.txData.prefix(4) == approveSelector)
        #expect(data.txData[36 ..< 68] == Data(repeating: 0xFF, count: 32))
    }
}

// MARK: - Helpers

private extension TronAllowanceCheckerTests {
    func makeSUT(rawAllowance: Decimal) -> TronAllowanceChecker {
        TronAllowanceChecker(
            blockchain: .tron(testnet: false),
            amountType: .token(value: token),
            walletAddress: anyOwner,
            allowanceProvider: TronAllowanceProviderStub(rawAllowance: rawAllowance),
            transactionDataBuilder: TronTransactionDataBuilderAdapter()
        )
    }

    func makeCoinSUT() -> TronAllowanceChecker {
        TronAllowanceChecker(
            blockchain: .tron(testnet: false),
            amountType: .coin,
            walletAddress: anyOwner,
            allowanceProvider: TronAllowanceProviderStub(rawAllowance: .zero),
            transactionDataBuilder: TronTransactionDataBuilderAdapter()
        )
    }
}

// MARK: - Doubles

private struct TronTransactionDataBuilderAdapter: TronTransactionDataBuilder {
    private let txBuilder = TronTransactionBuilder()

    func buildForApprove(spender: String, amount: Amount) throws -> Data {
        try txBuilder.buildForApprove(spender: spender, amount: amount)
    }
}

private struct TronAllowanceProviderStub: TronAllowanceProvider {
    let rawAllowance: Decimal

    func getAllowance(owner: String, spender: String, contractAddress: String) -> AnyPublisher<Decimal, Error> {
        Just(rawAllowance)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}
