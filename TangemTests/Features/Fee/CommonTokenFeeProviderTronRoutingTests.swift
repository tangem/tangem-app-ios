//
//  CommonTokenFeeProviderTronRoutingTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
@testable import Tangem

@Suite("CommonTokenFeeProvider — Tron input routing")
struct CommonTokenFeeProviderTronRoutingTests {
    private let tronFeeTokenItem: TokenItem = .blockchain(.init(.tron(testnet: false), derivationPath: nil))

    @Test("a Tron DEX input reaches the Tron loader and lands available")
    func dexTronInput_routesToTronLoader() async throws {
        let loader = TronTokenFeeLoaderSpy(fees: [makeFee(2)])
        let sut = makeSUT(loader: loader)
        let request = makeRequest()

        sut.setup(input: .dex(.tron(request: request)))
        #expect(sut.state.isSupported)

        await sut.updateFees().value

        #expect(loader.receivedRequests == [request])
        let fee = try sut.selectedTokenFee.value.get()
        #expect(fee.amount.value == 2)
    }

    @Test("an approve input becomes a calldata-priced Tron request")
    func approveInput_routesToTronLoader() async throws {
        let txData = Data([0x09, 0x5E, 0xA7, 0xB3, 0xFF])
        let contractAddress = "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t"
        let loader = TronTokenFeeLoaderSpy(fees: [makeFee(3)])
        let sut = makeSUT(loader: loader)

        sut.setup(input: .approve(txData: txData, toContractAddress: contractAddress))
        #expect(sut.state.isSupported)

        await sut.updateFees().value

        let expectedRequest = TronFeeRequestData(
            amount: BSDKAmount(with: .tron(testnet: false), type: .coin, value: 0),
            destination: contractAddress,
            callData: txData,
            memo: nil,
            otherNativeFee: nil
        )
        #expect(loader.receivedRequests == [expectedRequest])

        let fee = try sut.selectedTokenFee.value.get()
        #expect(fee.amount.value == 3)
    }

    @Test("a Tron DEX input is unsupported without a Tron loader")
    func dexTronInput_nonTronLoader_notSupported() {
        let sut = makeSUT(loader: NonTronTokenFeeLoaderStub())

        sut.setup(input: .dex(.tron(request: makeRequest())))

        guard case .unavailable(.notSupported) = sut.state else {
            Issue.record("Expected .unavailable(.notSupported), got \(sut.state)")
            return
        }
    }

    @Test("an approve input is unsupported without a Tron or Ethereum loader")
    func approveInput_nonTronLoader_notSupported() {
        let sut = makeSUT(loader: NonTronTokenFeeLoaderStub())

        sut.setup(input: .approve(txData: Data([0xAB]), toContractAddress: "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t"))

        guard case .unavailable(.notSupported) = sut.state else {
            Issue.record("Expected .unavailable(.notSupported), got \(sut.state)")
            return
        }
    }
}

// MARK: - Helpers

private extension CommonTokenFeeProviderTronRoutingTests {
    func makeSUT(loader: any TokenFeeLoader) -> CommonTokenFeeProvider {
        CommonTokenFeeProvider(
            feeTokenItem: tronFeeTokenItem,
            tokenFeeLoader: loader,
            customFeeProvider: nil,
            feeTokenItemBalanceProvider: MutableTokenBalanceProviderMock(balance: 25),
            supportingOptions: .all
        )
    }

    func makeRequest() -> TronFeeRequestData {
        TronFeeRequestData(
            amount: BSDKAmount(with: .tron(testnet: false), type: .coin, value: 50),
            destination: "TKJMd8JF5hevd2TQeSKvJzwQKgpRQVHpr6",
            callData: nil,
            memo: nil,
            otherNativeFee: nil
        )
    }

    func makeFee(_ value: Decimal) -> BSDKFee {
        BSDKFee(BSDKAmount(with: .tron(testnet: false), value: value))
    }
}

// MARK: - Doubles

private enum StubError: Error {
    case notNeeded
}

private final class TronTokenFeeLoaderSpy: TronTokenFeeLoader {
    private(set) var receivedRequests: [TronFeeRequestData] = []
    private let fees: [BSDKFee]

    init(fees: [BSDKFee]) {
        self.fees = fees
    }

    func getFee(request: TronFeeRequestData) async throws -> [BSDKFee] {
        receivedRequests.append(request)
        return fees
    }

    func estimatedFee(amount: Decimal) async throws -> [BSDKFee] { throw StubError.notNeeded }
    func getFee(amount: Decimal, destination: String) async throws -> [BSDKFee] { throw StubError.notNeeded }
}

private struct NonTronTokenFeeLoaderStub: TokenFeeLoader {
    func estimatedFee(amount: Decimal) async throws -> [BSDKFee] { throw StubError.notNeeded }
    func getFee(amount: Decimal, destination: String) async throws -> [BSDKFee] { throw StubError.notNeeded }
}
