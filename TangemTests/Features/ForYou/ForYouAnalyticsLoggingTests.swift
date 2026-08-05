//
//  ForYouAnalyticsLoggingTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Testing
import TangemFoundation
import TangemUI
@testable import Tangem

@Suite("Token Summary analytics")
struct TokenSummaryAnalyticsLoggingTests {
    @Test("Opening is reported once, and the period it opens on is not reported as a change")
    @MainActor
    func opensWithoutReportingItsInitialPeriod() {
        let logger = TokenSummaryAnalyticsLoggerSpy()
        _ = makeViewModel(period: .week, logger: logger)

        #expect(logger.events == [.opened])
    }

    @Test("Switching the period reports it; re-selecting the same one does not")
    @MainActor
    func reportsOnlyActualPeriodChanges() {
        let logger = TokenSummaryAnalyticsLoggerSpy()
        let viewModel = makeViewModel(period: .day, logger: logger)

        viewModel.selectedPeriod = .month
        viewModel.selectedPeriod = .month

        #expect(logger.events == [.opened, .interval(.month)])
    }

    @Test("The primary action reports the kind that was actually shown")
    @MainActor
    func reportsPrimaryActionKind() async throws {
        let logger = TokenSummaryAnalyticsLoggerSpy()
        let viewModel = makeViewModel(period: .day, primaryAction: .addFunds, logger: logger)

        // The action arrives through a publisher, so let the main-actor hop land first.
        await Task.yield()
        viewModel.primaryActionTapped()

        #expect(logger.events == [.opened, .primaryAction(.addFunds)])
    }

    @Test("A disabled primary action reports nothing")
    @MainActor
    func ignoresDisabledPrimaryAction() async throws {
        let logger = TokenSummaryAnalyticsLoggerSpy()
        let viewModel = makeViewModel(period: .day, primaryAction: .goToSwap(isEnabled: false), logger: logger)

        await Task.yield()
        viewModel.primaryActionTapped()

        #expect(logger.events == [.opened])
    }

    @MainActor
    private func makeViewModel(
        period: TokenSummaryPeriod,
        primaryAction: TokenSummaryPrimaryAction? = .goToSwap(isEnabled: true),
        logger: TokenSummaryAnalyticsLoggerSpy
    ) -> TokenSummaryViewModel {
        TokenSummaryViewModel(
            coinName: "Bitcoin",
            symbol: "BTC",
            tokenIconInfo: TokenIconInfo(
                name: "Bitcoin",
                blockchainIconAsset: nil,
                imageURL: nil,
                isCustom: false,
                customTokenColor: nil
            ),
            period: period,
            preloadedIndicators: [],
            primaryActionPublisher: Just(primaryAction).eraseToAnyPublisher(),
            analyticsLogger: logger,
            onPrimaryAction: { _ in },
            onClose: {}
        )
    }
}

// MARK: - Spy

private final class TokenSummaryAnalyticsLoggerSpy: TokenSummaryAnalyticsLogger {
    enum Event: Equatable {
        case opened
        case interval(TokenSummaryPeriod)
        case primaryAction(TokenSummaryPrimaryAction.Kind)
        case indicatorInfo(TokenSummaryIndicator.Kind)
    }

    private let state = OSAllocatedUnfairLock(initialState: [Event]())

    var events: [Event] {
        state.withLock { $0 }
    }

    func logOpened() {
        state.withLock { $0.append(.opened) }
    }

    func logInterval(period: TokenSummaryPeriod) {
        state.withLock { $0.append(.interval(period)) }
    }

    func logPrimaryAction(kind: TokenSummaryPrimaryAction.Kind) {
        state.withLock { $0.append(.primaryAction(kind)) }
    }

    func logIndicatorInfo(kind: TokenSummaryIndicator.Kind) {
        state.withLock { $0.append(.indicatorInfo(kind)) }
    }
}
