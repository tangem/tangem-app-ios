//
//  CommonTokenFeeProviderGaslessTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import Combine
import BlockchainSdk
import TangemFoundation
@testable import Tangem

@Suite("Gasless fee-provider signal")
struct CommonTokenFeeProviderGaslessTests {
    /// The provider must derive `isGasless` from its loader — the loader is the single source of truth
    /// (it's what pays the fee in a token via the relayer).
    @Test("provider.isGasless mirrors the loader", arguments: [true, false])
    func provider_forwardsLoaderIsGasless(loaderIsGasless: Bool) {
        let provider = makeProvider(loaderIsGasless: loaderIsGasless)
        #expect(provider.isGasless == loaderIsGasless)
    }

    @Test("isGaslessFeeSelected is true when the selected provider is gasless")
    func manager_gaslessSelected_isTrue() {
        let gasless = makeProvider(loaderIsGasless: true)
        let manager = CommonTokenFeeProvidersManager(feeProviders: [gasless], initialSelectedProvider: gasless)

        #expect(manager.isGaslessFeeSelected)
    }

    @Test("isGaslessFeeSelected is false when the selected provider pays the fee in the native coin")
    func manager_nonGaslessSelected_isFalse() {
        let coin = makeProvider(loaderIsGasless: false)
        let manager = CommonTokenFeeProvidersManager(feeProviders: [coin], initialSelectedProvider: coin)

        #expect(!manager.isGaslessFeeSelected)
    }
}

// MARK: - Helpers

private extension CommonTokenFeeProviderGaslessTests {
    var feeTokenItem: TokenItem {
        .token(
            .init(name: "USDC", symbol: "USDC", contractAddress: "0xUSDC", decimalCount: 6),
            .init(.ethereum(testnet: false), derivationPath: nil)
        )
    }

    func makeProvider(loaderIsGasless: Bool) -> CommonTokenFeeProvider {
        CommonTokenFeeProvider(
            feeTokenItem: feeTokenItem,
            tokenFeeLoader: GaslessFlagLoaderStub(isGasless: loaderIsGasless),
            customFeeProvider: nil,
            feeTokenItemBalanceProvider: TokenBalanceProviderTestsMock(balance: 0),
            supportingOptions: .all
        )
    }
}

// MARK: - Doubles

private struct GaslessFlagLoaderStub: TokenFeeLoader {
    let isGasless: Bool
    func estimatedFee(amount: Decimal) async throws -> [BSDKFee] { [] }
    func getFee(amount: Decimal, destination: String) async throws -> [BSDKFee] { [] }
}
