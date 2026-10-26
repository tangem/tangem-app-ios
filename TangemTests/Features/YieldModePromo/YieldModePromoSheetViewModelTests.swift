//
//  YieldModePromoSheetViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@MainActor
@Suite("YieldModePromoSheetViewModel")
struct YieldModePromoSheetViewModelTests {
    private let routable = StubRoutable()
    private let analytics = StubAnalyticsLogger()

    @Test("The cross logs an X close and dismisses, and the following disappearance logs nothing")
    func crossCloses() {
        let viewModel = makeViewModel()

        viewModel.close()
        viewModel.onDisappear()

        #expect(analytics.events == [.closed(.cross)])
        #expect(routable.events == [.dismiss])
    }

    @Test("A disappearance not started by the cross or the button is a swipe close, logged once")
    func swipeCloses() {
        let viewModel = makeViewModel()

        viewModel.onDisappear()
        viewModel.onDisappear()

        #expect(analytics.events == [.closed(.swipe)])
        #expect(routable.events.isEmpty)
    }

    @Test("Try Yield Mode logs the button, dismisses and opens Earn, and nothing closes afterwards")
    func tryYieldModeOpensEarn() {
        let viewModel = makeViewModel()

        viewModel.tryYieldMode()
        viewModel.close()
        viewModel.onDisappear()

        #expect(analytics.events == [.tryYieldMode])
        #expect(routable.events == [.dismiss, .openEarn])
    }

    @Test("Repeated taps on the cross or the button are handled once")
    func repeatedTapsAreHandledOnce() {
        let viewModel = makeViewModel()

        viewModel.tryYieldMode()
        viewModel.tryYieldMode()
        viewModel.close()

        #expect(analytics.events == [.tryYieldMode])
        #expect(routable.events == [.dismiss, .openEarn])
    }

    @Test("Without a presenter the taps log nothing, but a swipe still does")
    func noPresenterIgnoresTaps() {
        let viewModel = makeViewModel(routable: nil)

        viewModel.close()
        viewModel.tryYieldMode()
        viewModel.onDisappear()

        #expect(analytics.events == [.closed(.swipe)])
    }

    private func makeViewModel() -> YieldModePromoSheetViewModel {
        makeViewModel(routable: routable)
    }

    private func makeViewModel(
        routable: YieldModePromoSheetRoutable?
    ) -> YieldModePromoSheetViewModel {
        YieldModePromoSheetViewModel(
            data: YieldModePromoSheetData(
                apy: Decimal(string: "0.0612")!,
                tokensCount: 12,
                tokenSymbol: "USDT",
                blockchainName: "Ethereum"
            ),
            routable: routable,
            analyticsLogger: analytics
        )
    }
}

// MARK: - Stubs

private final class StubRoutable: YieldModePromoSheetRoutable {
    enum Event: Equatable {
        case dismiss
        case openEarn
    }

    private(set) var events: [Event] = []

    func dismissYieldModePromo() {
        events.append(.dismiss)
    }

    func openYieldModeEarn() {
        events.append(.openEarn)
    }
}

private final class StubAnalyticsLogger: YieldModePromoAnalyticsLogger {
    enum Event: Equatable {
        case closed(YieldModePromoCloseMethod)
        case tryYieldMode
    }

    private(set) var events: [Event] = []

    func logClosed(data: YieldModePromoSheetData, method: YieldModePromoCloseMethod) {
        events.append(.closed(method))
    }

    func logTryYieldMode(data: YieldModePromoSheetData) {
        events.append(.tryYieldMode)
    }
}
