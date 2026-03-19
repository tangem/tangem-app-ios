//
//  CommonAccountRateProviderTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import Combine
@testable import Tangem

@Suite("CommonAccountRateProviderTests")
struct CommonAccountRateProviderTests {
    @Test("Calculate if wallet models is empty")
    func calculateIfWalletModelsIsEmpty() async throws {
        // Given
        let (sut, walletModelsManager, totalBalanceProvider) = makeSUT(
            walletModels: [],
            totalBalance: .empty
        )

        // When
        let receivedRate = try await triggerUpdate(
            sut: sut,
            walletModelsManager: walletModelsManager,
            totalBalanceProvider: totalBalanceProvider
        )

        // Then
        guard case .failure = receivedRate else {
            Issue.record("Expected failure state")
            return
        }
    }

    @Test("Calculate if total balance is loading")
    func calculateIfTotalBalanceIsLoading() async throws {
        // Given
        let (sut, walletModelsManager, totalBalanceProvider) = makeSUT(
            walletModels: [createMockWalletModel()],
            totalBalance: .loading(cached: nil)
        )

        // When
        let receivedRate = try await triggerUpdate(
            sut: sut,
            walletModelsManager: walletModelsManager,
            totalBalanceProvider: totalBalanceProvider
        )

        // Then
        guard case .loading = receivedRate else {
            Issue.record("Expected loading state")
            return
        }
    }

    @Test("Calculate if total balance is failed")
    func calculateIfTotalBalanceIsFailed() async throws {
        // Given
        let (sut, walletModelsManager, totalBalanceProvider) = makeSUT(
            walletModels: [createMockWalletModel()],
            totalBalance: .failed(cached: nil, failedItems: [])
        )

        // When
        let receivedRate = try await triggerUpdate(
            sut: sut,
            walletModelsManager: walletModelsManager,
            totalBalanceProvider: totalBalanceProvider
        )

        // Then
        guard case .failure = receivedRate else {
            Issue.record("Expected failure state")
            return
        }
    }

    @Test("Calculate if total balance is zero")
    func calculateIfTotalBalanceIsZero() async throws {
        // Given
        let (sut, walletModelsManager, totalBalanceProvider) = makeSUT(
            walletModels: [
                createMockWalletModel(fiatBalance: 0, priceChange24h: 0.06),
                createMockWalletModel(fiatBalance: 0, priceChange24h: 0.00),
            ],
            totalBalance: .loaded(balance: 0)
        )

        // When
        let receivedRate = try await triggerUpdate(
            sut: sut,
            walletModelsManager: walletModelsManager,
            totalBalanceProvider: totalBalanceProvider
        )

        // Then
        guard case .loaded(let quote) = receivedRate else {
            Issue.record("Expected loaded state")
            return
        }
        #expect(quote.priceChange24h == 0)
    }

    @Test("Calculate weighted average price change")
    func calculateWeightedAveragePriceChange() async throws {
        // Given
        // • USDT — 50% (5/10), +6%
        // • BTC — 30% (3/10), -2%
        // • ETH — 20% (2/10), +4%
        // Expected: (0.50 × 6%) + (0.30 × -2%) + (0.20 × 4%) = 3.2%
        let (sut, walletModelsManager, totalBalanceProvider) = makeSUT(
            walletModels: [
                createMockWalletModel(fiatBalance: 5, priceChange24h: 0.06),
                createMockWalletModel(fiatBalance: 3, priceChange24h: -0.02),
                createMockWalletModel(fiatBalance: 2, priceChange24h: 0.04),
            ],
            totalBalance: .loaded(balance: 10)
        )

        // When
        let receivedRate = try await triggerUpdate(
            sut: sut,
            walletModelsManager: walletModelsManager,
            totalBalanceProvider: totalBalanceProvider
        )

        // Then
        guard case .loaded(let quote) = receivedRate else {
            Issue.record("Expected loaded state")
            return
        }

        let expected = Decimal(string: "0.032")
        #expect(quote.priceChange24h == expected, "Weighted average should be 3.2%")
    }

    @Test("Calculate ignores wallet models without quote")
    func calculateIgnoresWalletModelsWithoutQuote() async throws {
        // Given
        let (sut, walletModelsManager, totalBalanceProvider) = makeSUT(
            walletModels: [
                createMockWalletModel(fiatBalance: 5, priceChange24h: 0.10),
                createMockWalletModel(fiatBalance: 5, priceChange24h: nil),
            ],
            totalBalance: .loaded(balance: 10)
        )

        // When
        let receivedRate = try await triggerUpdate(
            sut: sut,
            walletModelsManager: walletModelsManager,
            totalBalanceProvider: totalBalanceProvider
        )

        // Then
        guard case .loaded(let quote) = receivedRate else {
            Issue.record("Expected loaded state")
            return
        }

        // Only first wallet should be counted: 0.5 * 0.10 = 0.05 (5%)
        let expected = Decimal(string: "0.05")
        #expect(quote.priceChange24h == expected)
    }

    @Test("Calculate ignores wallet models with zero balance")
    func calculateIgnoresWalletModelsWithZeroBalance() async throws {
        // Given
        let (sut, walletModelsManager, totalBalanceProvider) = makeSUT(
            walletModels: [
                createMockWalletModel(fiatBalance: 10, priceChange24h: 0.05),
                createMockWalletModel(fiatBalance: 0, priceChange24h: 0.20),
            ],
            totalBalance: .loaded(balance: 10)
        )

        // When
        let receivedRate = try await triggerUpdate(
            sut: sut,
            walletModelsManager: walletModelsManager,
            totalBalanceProvider: totalBalanceProvider
        )

        // Then
        guard case .loaded(let quote) = receivedRate else {
            Issue.record("Expected loaded state")
            return
        }

        // Only first wallet should be counted: 1.0 * 0.05 = 0.05 (5%)
        let expected = Decimal(string: "0.05")
        #expect(quote.priceChange24h == expected)
    }

    @Test("Price change updates when token balance transitions from loading to loaded")
    func priceChangeUpdatesWhenTokenBalanceTransitionsFromLoadingToLoaded() async throws {
        // Given
        // Setup: 2 tokens loaded, 1 token loading with nil balance
        // Token 1: 100 USDT, +5%
        // Token 2: 100 USDT, -3%
        // Token 3: Loading, will load with 0 USDT, +10%
        // Total balance: 200 USDT (unchanged when token 3 loads)

        let token1 = createMockWalletModel(fiatBalance: 100, priceChange24h: 0.05)
        let token2 = createMockWalletModel(fiatBalance: 100, priceChange24h: -0.03)
        let token3LoadingProvider = MutableTokenBalanceProviderMock(initialState: .loading(nil))
        let token3 = createMockWalletModelWithProvider(
            balanceProvider: token3LoadingProvider,
            priceChange24h: 0.10
        )

        let (sut, walletModelsManager, totalBalanceProvider) = makeSUT(
            walletModels: [token1, token2, token3],
            totalBalance: .loaded(balance: 200)
        )

        // Initial trigger to establish baseline
        _ = try await triggerUpdate(
            sut: sut,
            walletModelsManager: walletModelsManager,
            totalBalanceProvider: totalBalanceProvider
        )

        // When: Token 3 finishes loading with 0 balance (total unchanged)
        let receivedRate = try await triggerBalanceUpdate(sut: sut) {
            token3LoadingProvider.updateBalance(.loaded(0))
        }

        // Then: Price change should be recalculated
        // Initial: (0.5 × 5%) + (0.5 × -3%) = 1%
        // After: Token 3 has 0 balance, so weights unchanged, but it's now included in calculation
        // Result should still be (0.5 × 5%) + (0.5 × -3%) = 1%
        guard case .loaded(let quote) = receivedRate else {
            Issue.record("Expected loaded state")
            return
        }

        let expected = Decimal(string: "0.01")
        #expect(quote.priceChange24h == expected, "Price change should be recalculated even when total balance unchanged")
    }

    @Test("Price change updates when token balance changes")
    func priceChangeUpdatesWhenTokenBalanceChanges() async throws {
        // Given
        // Token 1: 100 USDT, +6%
        // Token 2: 100 USDT, -2%
        // Total: 200 USDT
        // Expected: (0.5 × 6%) + (0.5 × -2%) = 2%

        let token1Provider = MutableTokenBalanceProviderMock(balance: 100)
        let token1 = createMockWalletModelWithProvider(
            balanceProvider: token1Provider,
            priceChange24h: 0.06
        )
        let token2 = createMockWalletModel(fiatBalance: 100, priceChange24h: -0.02)

        let (sut, walletModelsManager, totalBalanceProvider) = makeSUT(
            walletModels: [token1, token2],
            totalBalance: .loaded(balance: 200)
        )

        // Initial trigger
        _ = try await triggerUpdate(
            sut: sut,
            walletModelsManager: walletModelsManager,
            totalBalanceProvider: totalBalanceProvider
        )

        // When: Token 1 balance increases to 200 USDT
        // New total: 300 USDT
        // New weights: Token 1 = 66.67%, Token 2 = 33.33%
        // Expected: (0.67 × 6%) + (0.33 × -2%) = 3.36%
        totalBalanceProvider.totalBalance = .loaded(balance: 300)
        let receivedRate = try await triggerBalanceUpdate(sut: sut) {
            token1Provider.updateBalance(.loaded(200))
            totalBalanceProvider.sendUpdate()
        }

        // Then
        guard case .loaded(let quote) = receivedRate else {
            Issue.record("Expected loaded state")
            return
        }

        let expected = Decimal(string: "0.0336")!
        let tolerance = Decimal(string: "0.001")! // 0.1% tolerance for rounding errors

        let priceChange = try #require(quote.priceChange24h)
        let difference = abs(priceChange - expected)

        #expect(
            difference <= tolerance,
            "Price change should reflect new balance weights. Expected: \(expected), got: \(String(describing: quote.priceChange24h)), difference: \(difference)"
        )
    }

    @Test("Price change updates on multiple token balance changes")
    func priceChangeUpdatesOnMultipleTokenBalanceChanges() async throws {
        // Given: 3 tokens with dynamic balance providers
        let token1Provider = MutableTokenBalanceProviderMock(balance: 100)
        let token1 = createMockWalletModelWithProvider(
            balanceProvider: token1Provider,
            priceChange24h: 0.05
        )

        let token2Provider = MutableTokenBalanceProviderMock(balance: 100)
        let token2 = createMockWalletModelWithProvider(
            balanceProvider: token2Provider,
            priceChange24h: 0.10
        )

        let token3Provider = MutableTokenBalanceProviderMock(balance: 100)
        let token3 = createMockWalletModelWithProvider(
            balanceProvider: token3Provider,
            priceChange24h: -0.05
        )

        let (sut, walletModelsManager, totalBalanceProvider) = makeSUT(
            walletModels: [token1, token2, token3],
            totalBalance: .loaded(balance: 300)
        )

        // Initial trigger
        _ = try await triggerUpdate(
            sut: sut,
            walletModelsManager: walletModelsManager,
            totalBalanceProvider: totalBalanceProvider
        )

        // When: Update token 1 balance
        // Token 1: 200, Token 2: 100, Token 3: 100
        // Total: 400, Weights: 50%, 25%, 25%
        // Expected: (0.5 × 5%) + (0.25 × 10%) + (0.25 × -5%) = 3.75%
        totalBalanceProvider.totalBalance = .loaded(balance: 400)
        let rate1 = try await triggerBalanceUpdate(sut: sut) {
            token1Provider.updateBalance(.loaded(200))
            totalBalanceProvider.sendUpdate()
        }

        guard case .loaded(let quote1) = rate1 else {
            Issue.record("Expected loaded state after first update")
            return
        }

        let expected1 = Decimal(string: "0.0375")
        #expect(quote1.priceChange24h == expected1, "First update should calculate correctly")

        // When: Update token 2 balance
        // Token 1: 200, Token 2: 200, Token 3: 100
        // Total: 500, Weights: 40%, 40%, 20%
        // Expected: (0.4 × 5%) + (0.4 × 10%) + (0.2 × -5%) = 5%
        totalBalanceProvider.totalBalance = .loaded(balance: 500)
        let rate2 = try await triggerBalanceUpdate(sut: sut) {
            token2Provider.updateBalance(.loaded(200))
            totalBalanceProvider.sendUpdate()
        }

        guard case .loaded(let quote2) = rate2 else {
            Issue.record("Expected loaded state after second update")
            return
        }

        let expected2 = Decimal(string: "0.05")
        #expect(quote2.priceChange24h == expected2, "Second update should calculate correctly")
    }
}

// MARK: - Helpers

private func makeSUT(
    walletModels: [WalletModelTestsMock],
    totalBalance: TotalBalanceState
) -> (CommonAccountRateProvider, WalletModelsManagerTestsMock, TotalBalanceProviderTestsMock) {
    let walletModelsManager = WalletModelsManagerTestsMock()
    let totalBalanceProvider = TotalBalanceProviderTestsMock()

    walletModelsManager.walletModels = walletModels
    totalBalanceProvider.totalBalance = totalBalance

    let sut = CommonAccountRateProvider(
        walletModelsManager: walletModelsManager,
        totalBalanceProvider: totalBalanceProvider
    )

    return (sut, walletModelsManager, totalBalanceProvider)
}

private func triggerUpdate(
    sut: CommonAccountRateProvider,
    walletModelsManager: WalletModelsManagerTestsMock,
    totalBalanceProvider: TotalBalanceProviderTestsMock
) async throws -> RateValue<AccountQuote> {
    try await waitForRateUpdate(sut: sut) {
        walletModelsManager.sendUpdate()
        totalBalanceProvider.sendUpdate()
    }
}

private func waitForRateUpdate(
    sut: CommonAccountRateProvider,
    trigger: @escaping () -> Void,
    timeout: TimeInterval = 1.0
) async throws -> RateValue<AccountQuote> {
    try await withCheckedThrowingContinuation { continuation in
        var cancellable: AnyCancellable?
        cancellable = sut.accountRatePublisher
            .dropFirst()
            .debounce(for: .milliseconds(10), scheduler: DispatchQueue.main)
            .timeout(.seconds(timeout), scheduler: DispatchQueue.main)
            .first()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        continuation.resume(throwing: error)
                    }
                    cancellable?.cancel()
                },
                receiveValue: { rate in
                    continuation.resume(returning: rate)
                }
            )

        trigger()
    }
}

private func createMockWalletModel(
    fiatBalance: Decimal = 0,
    priceChange24h: Decimal? = nil
) -> WalletModelTestsMock {
    WalletModelTestsMock(
        fiatBalance: fiatBalance,
        priceChange24h: priceChange24h
    )
}

private func createMockWalletModelWithProvider(
    balanceProvider: TokenBalanceProvider,
    priceChange24h: Decimal?
) -> WalletModelTestsMock {
    WalletModelTestsMock(
        fiatBalanceProvider: balanceProvider,
        priceChange24h: priceChange24h
    )
}

private func triggerBalanceUpdate(
    sut: CommonAccountRateProvider,
    trigger: @escaping () -> Void
) async throws -> RateValue<AccountQuote> {
    try await waitForRateUpdate(sut: sut, trigger: trigger)
}
