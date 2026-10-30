//
//  PolymarketOrderPreviewDoubles.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemPolymarket

final class PolymarketOrderPreviewAPIProvider: PolymarketAPIProvider {
    private let quote: PolymarketOrderQuote

    init(quote: PolymarketOrderQuote = .preview) {
        self.quote = quote
    }

    func orderQuote(request: PolymarketOrderQuoteRequest) async throws -> PolymarketOrderQuote {
        quote
    }

    func categories(locale: String?) async throws -> [PolymarketCategory] { [] }

    func events(request: PolymarketEventsRequest) async throws -> PolymarketEventsPage {
        PolymarketEventsPage(events: [], cursor: nil, hasNext: false)
    }

    func event(id: String) async throws -> PolymarketEvent {
        throw CancellationError()
    }

    func search(request: PolymarketSearchRequest) async throws -> PolymarketSearchResult {
        PolymarketSearchResult(events: [], page: request.page, total: 0, hasNext: false)
    }

    func series() async throws -> [PolymarketSeries] { [] }

    func seriesEvents(seriesId: String) async throws -> PolymarketSeriesEvents {
        throw CancellationError()
    }

    func positions(request: PolymarketPositionsRequest) async throws -> PolymarketPositionsPage {
        PolymarketPositionsPage(positions: [], receivedCount: 0, nextCursor: nil)
    }

    func closedPositions(request: PolymarketClosedPositionsRequest) async throws -> PolymarketClosedPositionsPage {
        PolymarketClosedPositionsPage(positions: [], receivedCount: 0, nextCursor: nil)
    }

    func positionOutcome(request: PolymarketPositionOutcomeRequest) async throws -> PolymarketPosition? {
        nil
    }

    func activity(request: PolymarketActivityRequest) async throws -> PolymarketActivityPage {
        PolymarketActivityPage(records: [], receivedCount: 0, nextCursor: nil)
    }

    func reconcileDeposits(depositWalletAddress: String) async throws -> PolymarketDepositsScan {
        PolymarketDepositsScan(state: .scanning, retryAfter: 0)
    }
}

// MARK: - Geoblock

final class PolymarketOrderPreviewGeoblockStateProvider: PolymarketGeoblockStateProvider {
    let state: PolymarketGeoblockState

    var statePublisher: AnyPublisher<PolymarketGeoblockState, Never> {
        .just(output: state)
    }

    init(state: PolymarketGeoblockState = .allowed) {
        self.state = state
    }

    func refresh() {}
}

// MARK: - Quote

extension PolymarketOrderQuote {
    static let preview = PolymarketOrderQuote(
        status: .full,
        side: .buy,
        shares: Decimal(string: "138.24")!,
        notional: 100,
        expectedExecutionAmount: Decimal(string: "138.24")!,
        averagePrice: Decimal(string: "0.72")!,
        worstCasePrice: Decimal(string: "0.735")!,
        fees: PolymarketOrderFees(
            market: Decimal(string: "0.3")!,
            builder: Decimal(string: "0.2")!,
            total: Decimal(string: "0.5")!
        ),
        total: Decimal(string: "100.5")!,
        builderCode: "0x00000000000000000000000000000000000000000000000000000000000000aa",
        minOrderSize: 5,
        minOrderAmount: 1,
        tickSize: Decimal(string: "0.001")!,
        isLive: false,
        version: .v1,
        exchange: "0xE111180000d2663C0091e4f400237545B87B996B",
        signingDomainVersion: "2"
    )
}

struct PolymarketOrderPreviewPlacementService: PolymarketOrderPlacementService {
    func place(
        quote: PolymarketOrderQuote,
        market: PolymarketMarket,
        outcome: PolymarketOutcome
    ) async throws -> PolymarketOrderPlacement {
        throw CancellationError()
    }
}
