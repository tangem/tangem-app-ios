//
//  SwapFlowConfigurationTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("SwapFlowConfiguration pair reversal")
struct SwapFlowConfigurationTests {
    @Test("An ordinary swap, where both sides can change, keeps the reversal button")
    func ordinarySwapKeepsTheReversal() {
        #expect(SwapFlowConfiguration.default.isPairReversalAvailable)
    }

    @Test("A pinned source hides the reversal even when the flow forgot to turn it off")
    func pinnedSourceHidesTheReversal() {
        let configuration = SwapFlowConfiguration(
            isPairReversalEnabled: true,
            sourceTokenSelection: .fixed,
            receiveTokenSelection: .selectable(.unrestricted),
            summaryTitle: nil
        )

        #expect(configuration.isPairReversalAvailable == false)
    }

    @Test("A receive side that follows the source hides the reversal even when the flow forgot to turn it off")
    func followingReceiveSideHidesTheReversal() {
        let configuration = SwapFlowConfiguration(
            isPairReversalEnabled: true,
            sourceTokenSelection: .selectable(.unrestricted),
            receiveTokenSelection: .followsSource(SourceEchoingDestinationResolver()),
            summaryTitle: nil
        )

        #expect(configuration.isPairReversalAvailable == false)
    }

    @Test("A flow that turns the reversal off keeps it off with both sides selectable")
    func explicitOptOutStaysOff() {
        let configuration = SwapFlowConfiguration(
            isPairReversalEnabled: false,
            sourceTokenSelection: .selectable(.unrestricted),
            receiveTokenSelection: .selectable(.unrestricted),
            summaryTitle: nil
        )

        #expect(configuration.isPairReversalAvailable == false)
    }
}

// MARK: - Doubles

private final class SourceEchoingDestinationResolver: SwapDestinationTokenResolver {
    func resolveDestination(for source: SendSwapableToken) -> SendReceiveToken {
        source
    }
}
