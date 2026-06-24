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

    func getGasPrice() -> AnyPublisher<BigUInt, Error> { Empty().eraseToAnyPublisher() }
    func getGasLimit(to: String, from: String, value: String?, data: String?) -> AnyPublisher<BigUInt, Error> { Empty().eraseToAnyPublisher() }
    func getFeeHistory() -> AnyPublisher<EthereumFeeHistory, Error> { Empty().eraseToAnyPublisher() }
    func getAllowance(owner: String, spender: String, contractAddress: String) -> AnyPublisher<Decimal, Error> { Empty().eraseToAnyPublisher() }
    func getAllowanceRaw(owner: String, spender: String, contractAddress: String) -> AnyPublisher<String, Error> { Empty().eraseToAnyPublisher() }
    func getBalance(_ address: String) -> AnyPublisher<Decimal, Error> { Empty().eraseToAnyPublisher() }
    func getTxCount(_ address: String) -> AnyPublisher<Int, Error> { Empty().eraseToAnyPublisher() }
    func getPendingTxCount(_ address: String) -> AnyPublisher<Int, Error> { Empty().eraseToAnyPublisher() }
    func getSmartContractNonce(for address: String) -> AnyPublisher<Int, Error> { Empty().eraseToAnyPublisher() }
}
