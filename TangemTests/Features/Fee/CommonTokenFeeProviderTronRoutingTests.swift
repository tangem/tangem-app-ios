//
//  CommonTokenFeeProviderTronRoutingTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
@testable import TangemExpress
@testable import Tangem

@Suite("CommonTokenFeeProvider — Tron input routing")
struct CommonTokenFeeProviderTronRoutingTests {
    private let tronFeeTokenItem: TokenItem = .blockchain(.init(.tron(testnet: false), derivationPath: nil))

    @Test("a CEX input is unsupported with a Tron gasless loader")
    func cexInput_tronGaslessLoader_notSupported() {
        let token = Token(
            name: "USDT",
            symbol: "USDT",
            contractAddress: "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t",
            decimalCount: 6
        )
        let loader = CommonTronGaslessTokenFeeLoader(
            tokenItem: .token(token, .init(.tron(testnet: false), derivationPath: nil)),
            feeToken: BSDKToken(
                name: token.name,
                symbol: token.symbol,
                contractAddress: token.contractAddress,
                decimalCount: token.decimalCount
            ),
            sourceAddress: "TSourceAddress"
        )
        let sut = makeSUT(loader: loader)

        sut.setup(input: .cex(amount: 10))

        guard case .unavailable(.notSupported) = sut.state else {
            Issue.record("Expected .unavailable(.notSupported), got \(sut.state)")
            return
        }
    }

    @Test("a CEX transaction input reaches a regular loader with its destination")
    func cexTransactionInput_routesToRegularLoader() async throws {
        let loader = CEXTokenFeeLoaderSpy(fees: [makeFee(4)])
        let sut = makeSUT(loader: loader)

        sut.setup(input: .cex(amount: 10, destination: "TDestinationAddress"))
        await sut.updateFees().value

        #expect(loader.receivedAmount == 10)
        #expect(loader.receivedDestination == "TDestinationAddress")
        let fee = try sut.selectedTokenFee.value.get()
        #expect(fee.amount.value == 4)
    }

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

@Suite("CommonTokenFeeProvidersManager — CEX input routing")
struct CommonTokenFeeProvidersManagerCEXRoutingTests {
    @Test("a CEX transaction forwards its destination to the selected loader and returns its fee")
    func cexTransaction_routesDestinationAndReturnsFee() async throws {
        let tokenItem = TokenItem.blockchain(.init(.tron(testnet: false), derivationPath: nil))
        let loadedFee = BSDKFee(BSDKAmount(with: .tron(testnet: false), value: 4))
        let loader = CEXTokenFeeLoaderSpy(fees: [loadedFee])
        let provider = CommonTokenFeeProvider(
            feeTokenItem: tokenItem,
            tokenFeeLoader: loader,
            customFeeProvider: nil,
            feeTokenItemBalanceProvider: MutableTokenBalanceProviderMock(balance: 25),
            supportingOptions: .all
        )
        let sut = CommonTokenFeeProvidersManager(
            feeProviders: [provider],
            initialSelectedProvider: provider,
            ownerAddress: nil
        )

        let result = try await sut.transactionFee(data: .cex(data: ExpressTransactionData(
            requestId: "",
            fromAmount: 10,
            toAmount: 20,
            expressTransactionId: "",
            transactionType: .swap,
            sourceAddress: nil,
            destinationAddress: "TDestinationAddress",
            extraDestinationId: nil,
            txValue: 10,
            txData: nil,
            otherNativeFee: nil,
            estimatedGasLimit: nil,
            externalTxId: nil,
            externalTxURL: nil,
            payInAddress: ""
        )))

        #expect(loader.receivedAmount == 10)
        #expect(loader.receivedDestination == "TDestinationAddress")
        #expect(result.amount.value == loadedFee.amount.value)
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

private final class CEXTokenFeeLoaderSpy: TokenFeeLoader {
    private(set) var receivedAmount: Decimal?
    private(set) var receivedDestination: String?
    private let fees: [BSDKFee]

    init(fees: [BSDKFee]) {
        self.fees = fees
    }

    func estimatedFee(amount: Decimal) async throws -> [BSDKFee] {
        throw StubError.notNeeded
    }

    func getFee(amount: Decimal, destination: String) async throws -> [BSDKFee] {
        receivedAmount = amount
        receivedDestination = destination
        return fees
    }
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
