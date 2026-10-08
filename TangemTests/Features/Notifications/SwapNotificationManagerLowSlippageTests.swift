//
//  SwapNotificationManagerLowSlippageTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemExpress
@testable import Tangem

@Suite("CommonSwapNotificationManager — low custom slippage warning")
struct SwapNotificationManagerLowSlippageTests {
    private let lowSlippage = SwapSlippage.custom(Decimal(string: "0.0011")!)

    @Test("Warns when the custom slippage is below half the provider default")
    func warnsBelowHalfDefault() throws {
        let sut = CommonSwapNotificationManager()

        let event = try #require(sut.mapLowCustomSlippageEvent(selected: makeProvider(), state: quotedState, slippage: lowSlippage).first)

        guard case .lowCustomSlippage(let slippage) = event else {
            Issue.record("Expected .lowCustomSlippage, got \(event)")
            return
        }

        #expect(slippage == PercentFormatter().format(Decimal(string: "0.0011")!, option: .customSlippage))
    }

    @Test("Does not warn at or above half the provider default", arguments: [Decimal(string: "0.0015")!, Decimal(string: "0.005")!])
    func noWarningAtOrAboveHalfDefault(customSlippage: Decimal) {
        let sut = CommonSwapNotificationManager()

        #expect(sut.mapLowCustomSlippageEvent(selected: makeProvider(), state: quotedState, slippage: .custom(customSlippage)).isEmpty)
    }

    @Test("Does not warn on Auto")
    func noWarningOnAuto() {
        let sut = CommonSwapNotificationManager()

        #expect(sut.mapLowCustomSlippageEvent(selected: makeProvider(), state: quotedState, slippage: .auto).isEmpty)
    }

    @Test("Does not warn for a provider without custom slippage")
    func noWarningForUnsupportedProvider() {
        let sut = CommonSwapNotificationManager()

        #expect(sut.mapLowCustomSlippageEvent(selected: makeProvider(isCustomSlippageSupported: false), state: quotedState, slippage: lowSlippage).isEmpty)
    }

    @Test("Does not warn when the provider has no default slippage")
    func noWarningWithoutDefault() {
        let sut = CommonSwapNotificationManager()

        #expect(sut.mapLowCustomSlippageEvent(selected: makeProvider(defaultSlippage: nil), state: quotedState, slippage: lowSlippage).isEmpty)
    }

    @Test("Does not warn without a selected provider")
    func noWarningWithoutProvider() {
        let sut = CommonSwapNotificationManager()

        #expect(sut.mapLowCustomSlippageEvent(selected: nil, state: quotedState, slippage: lowSlippage).isEmpty)
    }

    @Test("Does not warn while the slippage sheet cannot open: without a quote or after a failed one")
    func noWarningWhenSheetCannotOpen() {
        let sut = CommonSwapNotificationManager()

        #expect(sut.mapLowCustomSlippageEvent(selected: makeProvider(), state: .idle, slippage: lowSlippage).isEmpty)
        #expect(sut.mapLowCustomSlippageEvent(
            selected: makeProvider(),
            state: .requiredRefresh(occurredError: StubError(), quote: nil),
            slippage: lowSlippage
        ).isEmpty)
    }

    @Test("Tapping the warning asks the notification delegate to edit the slippage")
    func warningTapRequestsSlippageEditing() throws {
        let sut = CommonSwapNotificationManager()
        let event = try #require(sut.mapLowCustomSlippageEvent(selected: makeProvider(), state: quotedState, slippage: lowSlippage).first)
        var tappedAction: NotificationButtonActionType?

        let input = NotificationsFactory().buildNotificationInput(for: event) { _, action in tappedAction = action }

        guard case .tappable(hasChevron: true, let action) = input.style else {
            Issue.record("Expected a tappable warning, got \(input.style)")
            return
        }

        action(input.id)

        guard case .editSlippage = tappedAction else {
            Issue.record("Expected .editSlippage, got \(String(describing: tappedAction))")
            return
        }
    }
}

// MARK: - Helpers

private extension SwapNotificationManagerLowSlippageTests {
    struct StubError: Error {}

    var quotedState: SwapModel.LoadedState {
        .restriction(.hasPendingTransaction, quote: nil)
    }

    func makeProvider(defaultSlippage: Decimal? = Decimal(string: "0.003"), isCustomSlippageSupported: Bool = true) -> ExpressAvailableProvider {
        ExpressAvailableProviderFixture.make(
            state: .idle,
            slippage: defaultSlippage,
            isCustomSlippageSupported: isCustomSlippageSupported
        )
    }
}
