//
//  YieldModuleLendingLiquidityProviderTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BigInt
@testable import BlockchainSdk
import Testing

@Suite("Yield Module lending liquidity")
struct YieldModuleLendingLiquidityProviderTests {
    private static let module = "0x1111111111111111111111111111111111111111"
    private static let pool = "0x87870bca3f3fd6335c3f4ce8392d69350b4fa4e2"
    private static let weth = "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"

    @Test("Aave liquidity below the position caps the withdrawal")
    func liquidityCapsWithdrawal() async throws {
        let sut = makeSUT(liquidityWei: "400000000000000000")

        let available = try await sut.availableToWithdraw(nativePosition: 1)

        #expect(available == Decimal(string: "0.4"))
    }

    @Test("Aave liquidity above the position leaves the whole position")
    func liquidityAbovePosition() async throws {
        let sut = makeSUT(liquidityWei: "5000000000000000000")

        let available = try await sut.availableToWithdraw(nativePosition: 1)

        #expect(available == 1)
    }

    @Test("A liquidity lookup that fails or returns no amount throws instead of guessing", arguments: FailingRead.allCases)
    func failedLookupThrows(failingRead: FailingRead) async {
        let sut = makeSUT(liquidityWei: "400000000000000000", failingRead: failingRead)

        await #expect(throws: (any Error).self) {
            try await sut.availableToWithdraw(nativePosition: 1)
        }
    }

    @Test("A cancelled lookup throws the cancellation instead of an amount")
    func cancelledLookupThrowsCancellation() async {
        let sut = makeSUT(liquidityWei: "400000000000000000", failingRead: .liquidity, failure: CancellationError())

        await #expect(throws: CancellationError.self) {
            try await sut.availableToWithdraw(nativePosition: 1)
        }
    }

    @Test("A zero pool address from the module is never asked for liquidity")
    func zeroPoolAddressIsNotQueried() async {
        let sut = makeSUT(liquidityWei: "400000000000000000", poolAddress: Self.zeroAddress)

        await #expect(throws: YieldModuleError.self) {
            try await sut.availableToWithdraw(nativePosition: 1)
        }
    }
}

// MARK: - Fixtures

extension YieldModuleLendingLiquidityProviderTests {
    enum FailingRead: CaseIterable {
        case yieldModule
        case pool
        case wrappedNative
        case liquidity
        case emptyLiquidity
    }

    private static let zeroAddress = "0x0000000000000000000000000000000000000000"

    private func makeSUT(
        liquidityWei: String,
        failingRead: FailingRead? = nil,
        failure: Error = ReadError(),
        poolAddress: String = Self.pool
    ) -> YieldModuleLendingLiquidityProvider {
        func answer(_ read: FailingRead, with value: String) -> Result<String, Error> {
            failingRead == read ? .failure(failure) : .success(value)
        }

        let liquidity = failingRead == .emptyLiquidity ? .success("0x") : answer(.liquidity, with: Self.word(wei: liquidityWei))
        let liquidityMethod = VirtualUnderlyingBalanceMethod(assetContractAddress: Self.weth)

        let interactor = FakeSmartContractInteractor(responses: [
            Call(contract: Self.module, method: YieldModulePoolMethod()): answer(.pool, with: Self.word(address: poolAddress)),
            Call(contract: Self.module, method: WrappedNativeMethod()): answer(.wrappedNative, with: Self.word(address: Self.weth)),
            Call(contract: Self.pool, method: liquidityMethod): liquidity,
            Call(contract: Self.zeroAddress, method: liquidityMethod): .success(Self.word(wei: liquidityWei)),
        ])

        let yieldModule = answer(.yieldModule, with: Self.module)

        return CommonYieldModuleLendingLiquidityProvider(
            smartContractInteractor: interactor,
            decimalCount: 18,
            resolveYieldModule: { try yieldModule.get() }
        )
    }

    private static func word(wei: String) -> String {
        let hex = String(BigUInt(wei)!, radix: 16)
        return "0x" + String(repeating: "0", count: 64 - hex.count) + hex
    }

    private static func word(address: String) -> String {
        "0x" + String(repeating: "0", count: 24) + address.removeHexPrefix()
    }

    private struct ReadError: Error {}
}

private struct Call: Hashable {
    let contract: String
    let data: String

    init(contract: String, method: SmartContractMethod) {
        self.init(contract: contract, data: method.encodedData)
    }

    init(contract: String, data: String) {
        self.contract = contract.lowercased()
        self.data = data.lowercased()
    }
}

private final class FakeSmartContractInteractor: EVMSmartContractInteractor {
    private let responses: [Call: Result<String, Error>]

    init(responses: [Call: Result<String, Error>]) {
        self.responses = responses
    }

    func ethCall<Request: SmartContractRequest>(request: Request) -> AnyPublisher<String, Error> {
        let call = Call(contract: request.contractAddress, data: request.encodedData)

        return (responses[call] ?? .failure(UnexpectedCall()))
            .publisher
            .eraseToAnyPublisher()
    }

    private struct UnexpectedCall: Error {}
}
