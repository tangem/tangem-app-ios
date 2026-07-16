//
//  CommonEthereumTokenFeeLoaderTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Testing
import BigInt
import TangemFoundation
@testable import BlockchainSdk
@testable import Tangem

@Suite("CommonEthereumTokenFeeLoader — approve with swap fee")
struct CommonEthereumTokenFeeLoaderTests {
    private let marketApproveFeeValue = Decimal(string: "0.002")!

    /// The single market approve fee (index 1, with index 0 as fallback) is folded into EVERY swap speed option, so the same approve component is paid regardless of the chosen speed.
    @Test("folds the market approve fee into every swap option")
    func getApproveWithSwapFee_foldsSingleApproveIntoAllSwapOptions() async throws {
        let swapFees = [makeSwapFee(gasLimit: 200_000), makeSwapFee(gasLimit: 210_000), makeSwapFee(gasLimit: 220_000)]
        let approveFees = [makeApproveFee(value: Decimal(string: "0.001")!), makeApproveFee(value: marketApproveFeeValue)]
        let loader = makeLoader(swapFees: swapFees, approveFees: approveFees)

        let result = try await loader.getApproveWithSwapFee(request: makeRequest(), approveInput: makeApproveInput())

        #expect(result.count == swapFees.count)
        for fee in result {
            let parameters = try #require(fee.parameters as? ApproveWithSwapFeeParameters)
            #expect(parameters.approveFee.amount.value == marketApproveFeeValue)
        }
    }

    /// With no approve fee estimate the loader refuses rather than building swap options with a missing approve component.
    @Test("throws approveFeeNotFound when no approve fee is estimated")
    func getApproveWithSwapFee_noApproveFee_throws() async {
        let loader = makeLoader(swapFees: [makeSwapFee(gasLimit: 200_000)], approveFees: [])

        do {
            _ = try await loader.getApproveWithSwapFee(request: makeRequest(), approveInput: makeApproveInput())
            Issue.record("Expected approveFeeNotFound")
        } catch TokenFeeLoaderError.approveFeeNotFound {
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("bumps the EIP-1559 approve gas price by 15% and leaves the swap untouched")
    func getApproveWithSwapFee_eip1559_bumpsApproveGasPriceOnly() async throws {
        let swapFee = makeEIP1559Fee(maxFeePerGas: 50_000_000_000, priorityFee: 5_000_000_000, gasLimit: 200_000)
        let approveSlow = makeEIP1559Fee(maxFeePerGas: 30_000_000_000, priorityFee: 1_000_000_000, gasLimit: 90_000)
        let approveMarket = makeEIP1559Fee(maxFeePerGas: 40_000_000_000, priorityFee: 2_000_000_000, gasLimit: 100_000)
        let loader = makeLoader(swapFees: [swapFee], approveFees: [approveSlow, approveMarket])

        let result = try await loader.getApproveWithSwapFee(request: makeRequest(), approveInput: makeApproveInput())

        let parameters = try #require(result.first?.parameters as? ApproveWithSwapFeeParameters)

        let approveParameters = try #require(parameters.approveFee.parameters as? EthereumEIP1559FeeParameters)
        #expect(approveParameters.maxFeePerGas == 46_000_000_000)
        #expect(approveParameters.priorityFee == 2_300_000_000)

        let swapParameters = try #require(parameters.swapParameters as? EthereumEIP1559FeeParameters)
        #expect(swapParameters.maxFeePerGas == 50_000_000_000)
        #expect(swapParameters.priorityFee == 5_000_000_000)
    }

    @Test("bumps the legacy approve gas price by 15% and leaves the swap untouched")
    func getApproveWithSwapFee_legacy_bumpsApproveGasPriceOnly() async throws {
        let swapFee = makeLegacyFee(gasPrice: 30_000_000_000, gasLimit: 200_000)
        let approveSlow = makeLegacyFee(gasPrice: 18_000_000_000, gasLimit: 90_000)
        let approveMarket = makeLegacyFee(gasPrice: 20_000_000_000, gasLimit: 100_000)
        let loader = makeLoader(swapFees: [swapFee], approveFees: [approveSlow, approveMarket])

        let result = try await loader.getApproveWithSwapFee(request: makeRequest(), approveInput: makeApproveInput())

        let parameters = try #require(result.first?.parameters as? ApproveWithSwapFeeParameters)

        let approveParameters = try #require(parameters.approveFee.parameters as? EthereumLegacyFeeParameters)
        #expect(approveParameters.gasPrice == 23_000_000_000)

        let swapParameters = try #require(parameters.swapParameters as? EthereumLegacyFeeParameters)
        #expect(swapParameters.gasPrice == 30_000_000_000)
    }
}

// MARK: - Helpers

private extension CommonEthereumTokenFeeLoaderTests {
    func makeLoader(swapFees: [Fee], approveFees: [Fee]) -> CommonEthereumTokenFeeLoader {
        CommonEthereumTokenFeeLoader(
            feeBlockchain: .ethereum(testnet: false),
            tokenFeeLoader: TokenFeeLoaderStub(),
            ethereumNetworkProvider: FeeArrayNetworkProviderStub(swapFees: swapFees, approveFees: approveFees)
        )
    }

    func makeSwapFee(gasLimit: BigUInt) -> Fee {
        Fee(
            Amount(with: .ethereum(testnet: false), type: .coin, value: Decimal(string: "0.003")!),
            parameters: EthereumLegacyFeeParameters(gasLimit: gasLimit, gasPrice: 20_000_000_000)
        )
    }

    func makeEIP1559Fee(maxFeePerGas: BigUInt, priorityFee: BigUInt, gasLimit: BigUInt) -> Fee {
        Fee(
            Amount(with: .ethereum(testnet: false), type: .coin, value: Decimal(string: "0.003")!),
            parameters: EthereumEIP1559FeeParameters(gasLimit: gasLimit, maxFeePerGas: maxFeePerGas, priorityFee: priorityFee)
        )
    }

    func makeLegacyFee(gasPrice: BigUInt, gasLimit: BigUInt) -> Fee {
        Fee(
            Amount(with: .ethereum(testnet: false), type: .coin, value: Decimal(string: "0.003")!),
            parameters: EthereumLegacyFeeParameters(gasLimit: gasLimit, gasPrice: gasPrice)
        )
    }

    func makeApproveFee(value: Decimal) -> Fee {
        Fee(Amount(with: .ethereum(testnet: false), type: .coin, value: value))
    }

    func makeRequest() -> EthereumFeeRequestData {
        EthereumFeeRequestData(
            amount: Amount(with: .ethereum(testnet: false), type: .coin, value: 0),
            destination: "0x1111111111111111111111111111111111111111",
            txData: Data([0xAB]),
            otherNativeFee: nil
        )
    }

    func makeApproveInput() -> ApproveWithSwapInput {
        ApproveWithSwapInput(
            txData: Data([0xAB]),
            tokenContractAddress: "0x1111111111111111111111111111111111111111",
            owner: "0x2222222222222222222222222222222222222222",
            spender: "0x3333333333333333333333333333333333333333"
        )
    }
}

// MARK: - Doubles

private struct TokenFeeLoaderStub: TokenFeeLoader {
    func estimatedFee(amount: Decimal) async throws -> [BSDKFee] { [] }
    func getFee(amount: Decimal, destination: String) async throws -> [BSDKFee] { [] }
}

private struct FeeArrayNetworkProviderStub: EthereumNetworkProvider {
    let swapFees: [Fee]
    let approveFees: [Fee]

    func getFee(destination: String, value: String?, data: Data?, stateOverride: EthereumStateOverride?) -> AnyPublisher<[Fee], Error> {
        let fees = stateOverride == nil ? approveFees : swapFees
        return Just(fees).setFailureType(to: Error.self).eraseToAnyPublisher()
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
