//
//  CommonTokenFeeProviderMappingTests.swift
//  TangemTests
//
//  Covers CommonTokenFeeProvider.mapToLoadableTokenFee (surfaced via selectedTokenFee.value)
//  and the [REDACTED_INFO] fix: only a zero-balance native-coin fee token maps to
//  TokenFeeProviderError.notEnoughBalanceForFee (which drives the "insufficient balance for
//  network fee" notification). Gasless providers pay the fee in the token itself, so they must
//  NOT take that path — including the .notEnoughFeeBalance state and a zero token balance.
//

import Foundation
import Testing
import Combine
import BlockchainSdk
import TangemFoundation
@testable import Tangem

@Suite("CommonTokenFeeProvider — state → TokenFee.value mapping", .serialized)
struct CommonTokenFeeProviderMappingTests {
    // MARK: - Fixtures

    /// A regular token send pays the fee in the native coin, so the fee provider's fee token is the coin.
    private let nativeCoinFeeToken: TokenItem = .blockchain(.init(.ethereum(testnet: false), derivationPath: nil))
    /// A gasless provider pays the fee in the token itself (e.g. USDT/USDC), so its fee token is a token.
    private let gaslessTokenFeeToken: TokenItem = .token(
        .init(name: "USDT", symbol: "USDT", contractAddress: "0xUSDT", decimalCount: 6),
        .init(.ethereum(testnet: false), derivationPath: nil)
    )

    private func makeProvider(
        feeTokenItem: TokenItem,
        balance: Decimal,
        loader: any TokenFeeLoader = NoopFeeLoaderMock()
    ) -> CommonTokenFeeProvider {
        CommonTokenFeeProvider(
            feeTokenItem: feeTokenItem,
            tokenFeeLoader: loader,
            customFeeProvider: nil,
            feeTokenItemBalanceProvider: MutableTokenBalanceProviderMock(balance: balance),
            supportingOptions: .all
        )
    }

    // MARK: - .noTokenBalance (set by the balance observer on a zero fee-token balance)

    @Test("Zero native-coin balance → notEnoughBalanceForFee (token send / native-coin approve)")
    func noTokenBalance_nativeCoinFeeToken_mapsToNotEnoughBalanceForFee() {
        let sut = makeProvider(feeTokenItem: nativeCoinFeeToken, balance: 0)

        #expect(isNotEnoughBalanceForFee(sut.selectedTokenFee.value))
    }

    @Test("Zero gasless-token balance → generic providerUnavailable, NOT the native-coin notification")
    func noTokenBalance_gaslessTokenFeeToken_mapsToProviderUnavailable() {
        let sut = makeProvider(feeTokenItem: gaslessTokenFeeToken, balance: 0)

        #expect(isProviderUnavailable(sut.selectedTokenFee.value))
        #expect(!isNotEnoughBalanceForFee(sut.selectedTokenFee.value))
    }

    @Test("Positive native-coin balance → not a failure (state is available/idle, no fee error)")
    func positiveBalance_nativeCoinFeeToken_notNotEnoughBalanceForFee() {
        let sut = makeProvider(feeTokenItem: nativeCoinFeeToken, balance: 1)

        #expect(!isNotEnoughBalanceForFee(sut.selectedTokenFee.value))
    }

    // MARK: - .notEnoughFeeBalance (gasless execution reverted, token balance below the gasless threshold)

    @Test("Gasless notEnoughFeeBalance → providerUnavailable, NOT the native-coin notification")
    func gaslessNotEnoughFeeBalance_mapsToProviderUnavailable() async {
        // decimalValue for a 6-decimal token is 1_000_000, so a 5_000_000 minimum = 5 tokens.
        // Balance 1 < 5 → the provider enters .unavailable(.notEnoughFeeBalance).
        let loader = ThrowingFeeLoaderMock(error: TokenFeeLoaderError.gaslessExecutionReverted(gaslessMinTokenAmount: 5_000_000))
        let sut = makeProvider(feeTokenItem: gaslessTokenFeeToken, balance: 1, loader: loader)

        sut.setup(input: .common(amount: 0.5, destination: "0xTo"))
        await sut.updateFees().value

        #expect(isProviderUnavailable(sut.selectedTokenFee.value))
        #expect(!isNotEnoughBalanceForFee(sut.selectedTokenFee.value))
    }

    // MARK: - .notSupported / error passthrough

    @Test("Loader-not-found → unsupportedByProvider")
    func loaderNotFound_mapsToUnsupportedByProvider() async {
        let loader = ThrowingFeeLoaderMock(error: TokenFeeLoaderError.tokenFeeLoaderNotFound)
        let sut = makeProvider(feeTokenItem: nativeCoinFeeToken, balance: 1, loader: loader)

        sut.setup(input: .common(amount: 0.1, destination: "0xTo"))
        await sut.updateFees().value

        #expect(isUnsupportedByProvider(sut.selectedTokenFee.value))
    }

    @Test("EVM gas-estimation rejection passes through unchanged for the notification layer to route")
    func gasRequiredExceedsAllowance_passesThrough() async {
        // Partial native-coin balance (> 0, so no .noTokenBalance); gas estimation is rejected by the node.
        let loader = ThrowingFeeLoaderMock(error: ETHError.gasRequiredExceedsAllowance)
        let sut = makeProvider(feeTokenItem: nativeCoinFeeToken, balance: 0.0001, loader: loader)

        sut.setup(input: .common(amount: 0.00005, destination: "0xTo"))
        await sut.updateFees().value

        guard case .failure(let error) = sut.selectedTokenFee.value,
              case ETHError.gasRequiredExceedsAllowance = error else {
            Issue.record("Expected ETHError.gasRequiredExceedsAllowance to pass through, got \(sut.selectedTokenFee.value)")
            return
        }
    }

    // MARK: - Matchers

    private func isNotEnoughBalanceForFee(_ value: LoadingResult<BSDKFee, any Error>) -> Bool {
        if case .failure(let error) = value, case TokenFeeProviderError.notEnoughBalanceForFee = error { return true }
        return false
    }

    private func isProviderUnavailable(_ value: LoadingResult<BSDKFee, any Error>) -> Bool {
        if case .failure(let error) = value, case TokenFeeProviderError.providerUnavailable = error { return true }
        return false
    }

    private func isUnsupportedByProvider(_ value: LoadingResult<BSDKFee, any Error>) -> Bool {
        if case .failure(let error) = value, case TokenFeeProviderError.unsupportedByProvider = error { return true }
        return false
    }
}

// MARK: - Loader mocks

private struct NoopFeeLoaderMock: TokenFeeLoader {
    var isGasless: Bool { false }
    func estimatedFee(amount: Decimal) async throws -> [BSDKFee] { [] }
    func getFee(amount: Decimal, destination: String) async throws -> [BSDKFee] { [] }
}

private struct ThrowingFeeLoaderMock: TokenFeeLoader {
    let error: any Error

    var isGasless: Bool { false }
    func estimatedFee(amount: Decimal) async throws -> [BSDKFee] { throw error }
    func getFee(amount: Decimal, destination: String) async throws -> [BSDKFee] { throw error }
}
