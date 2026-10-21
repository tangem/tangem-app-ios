//
//  PolymarketOrderAddFundsTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
import TangemPolymarket
import TangemTestKit
@testable import Tangem

@Suite("Polymarket order add funds")
final class PolymarketOrderAddFundsTests: LeakTrackingTestSuite {
    @Test("A prepared deposit enables the button and a tap opens add funds")
    @MainActor
    func availableAddFundsOpens() async throws {
        let context = try await makeContext(readiness: prepared)

        context.sut.handleViewAction(.openAddFunds)

        #expect(context.sut.isAddFundsEnabled)
        #expect(context.routable.addFundsOpenings == 1)
        #expect(context.sut.alert == nil)
    }

    @Test("An unavailable deposit greys the button out and a tap explains itself instead of opening add funds")
    @MainActor
    func unavailableAddFundsShowsAlert() async throws {
        let context = try await makeContext(readiness: .unavailable)

        context.sut.handleViewAction(.openAddFunds)

        #expect(!context.sut.isAddFundsEnabled)
        #expect(context.routable.addFundsOpenings == 0)
        #expect(context.sut.alert != nil)
    }

    @Test("A prepared account with nothing to deposit counts as unavailable")
    @MainActor
    func preparedWithoutTargetsShowsAlert() async throws {
        let context = try await makeContext(readiness: .ready(makeReadiness(depositAvailability: .unavailable)))

        context.sut.handleViewAction(.openAddFunds)

        #expect(!context.sut.isAddFundsEnabled)
        #expect(context.sut.alert != nil)
    }

    @Test("While the deposit is still being prepared a tap does nothing")
    @MainActor
    func loadingAddFundsIgnoresTap() async throws {
        let context = try await makeContext(readiness: .loading)

        context.sut.handleViewAction(.openAddFunds)

        #expect(!context.sut.isAddFundsEnabled)
        #expect(context.routable.addFundsOpenings == 0)
        #expect(context.sut.alert == nil)
    }

    @Test("In a restricted region add funds opens the region warning, not the unavailable alert")
    @MainActor
    func restrictedRegionWinsOverUnavailableAddFunds() async throws {
        let context = try await makeContext(readiness: .unavailable, geoblock: .blocked)

        context.sut.handleViewAction(.openAddFunds)

        #expect(context.routable.regionWarnings == 1)
        #expect(context.routable.addFundsOpenings == 0)
        #expect(context.sut.alert == nil)
    }

    @Test("Closing a position offers no add funds row at all")
    @MainActor
    func sellingShowsNoPaymentRow() async throws {
        let context = try await makeContext(readiness: prepared, intent: .sell(shares: 5))

        #expect(context.sut.payment == nil)
    }

    @Test("A deposit prepared after the screen opened enables the button")
    @MainActor
    func lateReadinessEnablesButton() async throws {
        let context = try await makeContext(readiness: .loading)

        context.readiness.yield(prepared)

        try await settle { context.sut.isAddFundsEnabled }
    }
}

// MARK: - Fixtures

private extension PolymarketOrderAddFundsTests {
    struct Context {
        let sut: PolymarketOrderViewModel
        let routable: OrderRoutableSpy
        let readiness: AsyncStream<PolymarketAccountFundsInteractor.State>.Continuation
    }

    @MainActor
    func makeContext(
        readiness: PolymarketAccountFundsInteractor.State,
        geoblock: PolymarketGeoblockState = .allowed,
        intent: PolymarketOrderIntent = .buy(balance: .just(output: 200))
    ) async throws -> Context {
        let (stream, continuation) = AsyncStream<PolymarketAccountFundsInteractor.State>.makeStream()
        let routable = OrderRoutableSpy()

        let model = PolymarketOrderModel(
            market: .fixture,
            outcome: .fixture,
            eventTitle: "Fixture event",
            intent: intent,
            apiProvider: PolymarketAPIProviderStub(),
            geoblockStateProvider: PolymarketGeoblockStateProviderStub(state: geoblock),
            positionsService: nil,
            clobService: PolymarketCLOBServiceStub(),
            isAwaitingFundsPublisher: .just(output: false),
            collateralBalancePublisher: .just(output: 200),
            addFundsReadinessStream: stream
        )

        let sut = PolymarketOrderViewModel(model: trackForMemoryLeaks(model), coordinator: routable)

        continuation.yield(readiness)

        let isAddFundsEnabled = readiness.addFundsAvailability == .available

        try await settle {
            model.state.addFundsReadiness == readiness
                && model.state.geoblock == geoblock
                && sut.isAddFundsEnabled == isAddFundsEnabled
        }

        return Context(sut: sut, routable: routable, readiness: continuation)
    }

    var prepared: PolymarketAccountFundsInteractor.State {
        .ready(makeReadiness(depositAvailability: .available([
            PolymarketAccountFundsInteractor.DepositTarget(
                entry: PolymarketDepositAssetCatalog.usdcOnPolygon,
                tokenItem: PolymarketUtilities.usdcTokenItem,
                minCheckoutUSD: 2,
                fundingAddress: "0x2222222222222222222222222222222222222222"
            ),
        ])))
    }

    func makeReadiness(depositAvailability: PolymarketAccountFundsInteractor.DepositAvailability) -> PolymarketAccountFundsInteractor.Readiness {
        PolymarketAccountFundsInteractor.Readiness(
            depositWalletAddress: "0x1111111111111111111111111111111111111111",
            depositAvailability: depositAvailability,
            withdrawalAvailability: .available(minimumUSD: 2)
        )
    }
}

// MARK: - Doubles

private final class OrderRoutableSpy: PolymarketOrderRoutable {
    private(set) var addFundsOpenings = 0
    private(set) var regionWarnings = 0

    func closeOrder() {}

    func openMarketClosed() {}

    func openQuoteUnavailable() {}

    func openAddFunds() {
        addFundsOpenings += 1
    }

    func openRegionWarning() {
        regionWarnings += 1
    }

    func openSlippageSelector(percent: Decimal, onConfirm: @escaping (Decimal) -> Void) {}

    func openSummary(model: PolymarketOrderModel) {}

    func openFeeBreakdown(model: PolymarketOrderModel) {}

    func openResult(state: PolymarketOrderResultViewModel.State, content: PolymarketOrderResultViewModel.Content) {}

    func openLegalTerms(url: URL) {}

    func openSupport() {}
}
