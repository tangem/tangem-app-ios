//
//  YieldModePromoSheetManagerTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import Testing
import TangemFoundation
@testable import Tangem

@Suite("Yield Mode promo sheet manager", .timeLimit(.minutes(1)))
struct YieldModePromoSheetManagerTests {
    @Test("Ready once the fresh catalog, the positions and the Earn list are in, quoting the candidate")
    func readyWithCandidate() async {
        let earnLoader = EarnOffersLoaderSpy(result: .success(makeEarnResponse(total: 12)))
        let routable = RoutableSpy()
        let sut = makeSUT(earnLoader: earnLoader, routable: routable)

        #expect(await terminalState(of: sut) == .ready)
        #expect(earnLoader.callCount == 1)

        let data = await presentedData(of: sut, variant: "user_max_apy", routable: routable)
        #expect(data == YieldModePromoSheetData(apy: Decimal(string: "0.05")!, tokensCount: 12, tokenSymbol: "USDT", blockchainName: "Ethereum"))
    }

    @Test("A catalog that failed to load this launch is data not ready")
    func failedCatalog() async {
        let sut = makeSUT(catalog: .failed)

        #expect(await terminalState(of: sut) == .unavailable(.dataNotReady))
    }

    @Test("A failed catalog is data not ready without requesting the Earn list")
    func failedCatalogSkipsEarnRequest() async {
        let earnLoader = EarnOffersLoaderSpy(result: .success(makeEarnResponse(total: 12)))
        let sut = makeSUT(catalog: .failed, earnLoader: earnLoader)

        #expect(await terminalState(of: sut) == .unavailable(.dataNotReady))
        #expect(earnLoader.callCount == 0)
    }

    @Test("Waits while the catalog is loading and decides on the fresh one")
    func waitsForCatalog() async {
        let catalog = CurrentValueSubject<YieldModePromoCatalog, Never>(makeCatalog(.loading))
        let sut = makeSUT(catalogPublisher: catalog.eraseToAnyPublisher())

        let state = await firstState(of: sut) { catalog.send(makeCatalog(.loaded)) }

        #expect(state == .ready)
    }

    @Test("Waits while a position is loading and decides once it is in")
    func waitsForPositions() async {
        let positions = CurrentValueSubject<[YieldModePromoPosition], Never>([makePosition(balance: .loading, yieldState: .notActive)])
        let sut = makeSUT(positionsPublisher: positions.eraseToAnyPublisher())

        let state = await firstState(of: sut) { positions.send([makePosition(yieldState: .notActive)]) }

        #expect(state == .ready)
    }

    @Test("A failed Earn list is data not ready")
    func failedEarnList() async {
        let sut = makeSUT(earnLoader: EarnOffersLoaderSpy(result: .failure(StubError())))

        #expect(await terminalState(of: sut) == .unavailable(.dataNotReady))
    }

    @Test("An Earn list that reports offers but has no usable top row is data not ready")
    func malformedEarnList() async {
        let response = EarnDTO.List.Response(items: [], meta: EarnDTO.List.Meta(page: 1, limit: 1, total: 5, hasNext: false))
        let sut = makeSUT(earnLoader: EarnOffersLoaderSpy(result: .success(response)))

        #expect(await terminalState(of: sut) == .unavailable(.dataNotReady))
    }

    @Test("An empty Earn list leaves nothing to promote")
    func emptyEarnList() async {
        let sut = makeSUT(earnLoader: EarnOffersLoaderSpy(result: .success(makeEarnResponse(total: 0))))

        #expect(await terminalState(of: sut) == .unavailable(.noEligibleContent))
    }

    @Test("Without an eligible position there is nothing to promote and the Earn list is not requested")
    func noEligiblePosition() async {
        let earnLoader = EarnOffersLoaderSpy(result: .failure(StubError()))
        let sut = makeSUT(yieldState: .active, earnLoader: earnLoader)

        #expect(await terminalState(of: sut) == .unavailable(.noEligibleContent))
        #expect(earnLoader.callCount == 0)
    }

    @Test("A position that failed to refresh is data not ready")
    func failedPosition() async {
        let sut = makeSUT(yieldState: .failed)

        #expect(await terminalState(of: sut) == .unavailable(.dataNotReady))
    }

    @Test("Without a selected wallet there is nothing to promote")
    func noSelectedWallet() async {
        let sut = makeSUT(hasSelectedWallet: false)

        #expect(await terminalState(of: sut) == .unavailable(.noEligibleContent))
    }

    @Test("The promo runs under its own experiment")
    func declaresExperiment() {
        let sut = makeSUT()

        #expect(sut.experimentKey == .yieldModePromo)
    }

    @Test("The promo stays out of sessions opened from a link")
    func staysOutOfLinkSessions() {
        let sut = makeSUT()

        #expect(!sut.canHandlePresentation(MainScreenPromoSheetPresentationSettings(isOpenedFromLink: true)))
        #expect(sut.canHandlePresentation(MainScreenPromoSheetPresentationSettings(isOpenedFromLink: false)))
    }

    @Test("The source decides once and finishes, even though the positions never complete")
    func decidesOnce() async {
        let positions = CurrentValueSubject<[YieldModePromoPosition], Never>([makePosition(yieldState: .notActive)])
        let sut = makeSUT(positionsPublisher: positions.eraseToAnyPublisher())

        let states = try? await sut.statePublisher.collect().async()

        #expect(states == [.ready])
    }
}

// MARK: - Helpers

private extension YieldModePromoSheetManagerTests {
    func makeSUT(
        catalog loadState: YieldModuleMarketsLoadState = .loaded,
        catalogPublisher: AnyPublisher<YieldModePromoCatalog, Never>? = nil,
        yieldState: YieldModePromoPosition.YieldState = .notActive,
        positionsPublisher: AnyPublisher<[YieldModePromoPosition], Never>? = nil,
        hasSelectedWallet: Bool = true,
        earnLoader: EarnOffersLoaderSpy? = nil,
        routable: YieldModePromoSheetRoutable? = nil
    ) -> YieldModePromoSheetManager {
        let catalog = catalogPublisher ?? Just(makeCatalog(loadState)).eraseToAnyPublisher()
        let positions = positionsPublisher ?? Just([makePosition(yieldState: yieldState)]).eraseToAnyPublisher()

        return YieldModePromoSheetManager(
            catalogProvider: CatalogProviderStub(catalogPublisher: catalog),
            makePositionsProvider: { hasSelectedWallet ? PositionsProviderStub(positionsPublisher: positions) : nil },
            earnOffersLoader: earnLoader ?? EarnOffersLoaderSpy(result: .success(makeEarnResponse(total: 12))),
            analyticsLogger: AnalyticsLoggerStub(),
            routable: routable
        )
    }

    func terminalState(of sut: YieldModePromoSheetManager) async -> MainScreenPromoSheetManagerState? {
        try? await sut.statePublisher.first().async()
    }

    func firstState(of sut: YieldModePromoSheetManager, afterSubscribing action: () -> Void) async -> MainScreenPromoSheetManagerState {
        var cancellable: AnyCancellable?
        defer { cancellable?.cancel() }

        return await withCheckedContinuation { continuation in
            cancellable = sut.statePublisher.sink { continuation.resume(returning: $0) }
            action()
        }
    }

    func presentedData(of sut: YieldModePromoSheetManager, variant: String?, routable: RoutableSpy) async -> YieldModePromoSheetData? {
        await MainActor.run {
            sut.presentSheet(experimentVariant: variant) == nil ? nil : routable.presentedViewModel?.data
        }
    }

    func makeCatalog(_ loadState: YieldModuleMarketsLoadState) -> YieldModePromoCatalog {
        let market = YieldModuleMarketInfo(
            tokenContractAddress: "0xaaa",
            apy: Decimal(string: "0.05")!,
            isActive: true,
            chainId: 1,
            maxFeeNative: nil,
            maxFeeUSD: nil,
            incentive: nil
        )

        return YieldModePromoCatalog(loadState: loadState, markets: [market])
    }

    func makePosition(
        balance: YieldModePromoPosition.Balance = .loaded(10),
        yieldState: YieldModePromoPosition.YieldState
    ) -> YieldModePromoPosition {
        YieldModePromoPosition(
            chainId: 1,
            contractAddress: "0xaaa",
            tokenSymbol: "USDT",
            blockchainName: "Ethereum",
            balance: balance,
            fiatBalance: .loaded(10),
            yieldState: yieldState
        )
    }

    func makeEarnResponse(total: Int) -> EarnDTO.List.Response {
        let items = total > 0
            ? [
                EarnDTO.List.Item(
                    apy: "0.092",
                    networkId: "ethereum",
                    rewardType: "apy",
                    type: "yield",
                    token: EarnDTO.List.Token(id: "dai", symbol: "DAI", name: "Dai", address: "0xdai", decimalCount: 18)
                ),
            ]
            : []

        return EarnDTO.List.Response(items: items, meta: EarnDTO.List.Meta(page: 1, limit: 1, total: total, hasNext: false))
    }
}

// MARK: - Stubs

private struct StubError: Error {}

private struct CatalogProviderStub: YieldModePromoCatalogProvider {
    let catalogPublisher: AnyPublisher<YieldModePromoCatalog, Never>
}

private struct PositionsProviderStub: YieldModePromoPositionsProvider {
    let positionsPublisher: AnyPublisher<[YieldModePromoPosition], Never>
}

private final class EarnOffersLoaderSpy: YieldModePromoEarnOffersLoader {
    private let result: Result<EarnDTO.List.Response, Error>
    private let calls = OSAllocatedUnfairLock(initialState: 0)

    var callCount: Int {
        calls.withLock { $0 }
    }

    init(result: Result<EarnDTO.List.Response, Error>) {
        self.result = result
    }

    func loadYieldOffers() async throws -> EarnDTO.List.Response {
        calls.withLock { $0 += 1 }
        return try result.get()
    }
}

private struct AnalyticsLoggerStub: YieldModePromoAnalyticsLogger {
    func logClosed(data: YieldModePromoSheetData, method: YieldModePromoCloseMethod) {}

    func logTryYieldMode(data: YieldModePromoSheetData) {}
}

private final class RoutableSpy: YieldModePromoSheetRoutable {
    private(set) var presentedViewModel: YieldModePromoSheetViewModel?

    func presentYieldModePromo(_ viewModel: YieldModePromoSheetViewModel) {
        presentedViewModel = viewModel
    }

    func dismissYieldModePromo() {}

    func openYieldModeEarn() {}
}
