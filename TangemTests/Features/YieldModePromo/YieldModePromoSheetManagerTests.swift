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

    @Test("The shown and skipped events go through the analytics logger")
    func logsShownAndSkipped() async {
        let analytics = AnalyticsLoggerSpy()
        let routable = RoutableSpy()
        let sut = makeSUT(analytics: analytics, routable: routable)

        _ = await terminalState(of: sut)
        _ = await presentedData(of: sut, variant: "user_max_apy", routable: routable)
        sut.logShown()
        sut.logSkipped(.surfaceBusy)

        #expect(analytics.openedData.map(\.tokensCount) == [12])
        #expect(analytics.skipReasons == [.surfaceBusy])
    }

    @Test("The user_max_apy arm presents and logs the user's best rate")
    func userMaxApyArm() async {
        let expected = YieldModePromoSheetData(apy: Decimal(string: "0.05")!, tokensCount: 12, tokenSymbol: "USDT", blockchainName: "Ethereum")

        #expect(await presentedAndLoggedData(variant: "user_max_apy") == [expected, expected])
    }

    @Test("The global_max_apy arm presents and logs the top Earn offer")
    func globalMaxApyArm() async {
        let earnLoader = EarnOffersLoaderSpy(result: .success(makeEarnResponse(total: 12, topNetworkId: "polygon-pos")))
        let expected = YieldModePromoSheetData(apy: Decimal(string: "0.092")!, tokensCount: 12, tokenSymbol: "DAI", blockchainName: "Polygon")

        #expect(await presentedAndLoggedData(variant: "global_max_apy", earnLoader: earnLoader) == [expected, expected])
    }

    @Test("Control or no assignment presents nothing and logs neither Opened nor Skipped", arguments: ["control", nil] as [String?])
    func presentsNothingOutsideShowingArms(variant: String?) async {
        let analytics = AnalyticsLoggerSpy()
        let routable = RoutableSpy()
        let sut = makeSUT(analytics: analytics, routable: routable)
        #expect(await terminalState(of: sut) == .ready)

        let isPresented = await MainActor.run { sut.presentSheet(experimentVariant: variant) != nil }
        sut.logShown()

        #expect(!isPresented)
        #expect(routable.presentedViewModel == nil)
        #expect(analytics.openedData.isEmpty)
        #expect(analytics.skipReasons.isEmpty)
    }

    @Test("A sheet the coordinator refuses to present is skipped as a busy surface and logs no Opened")
    func refusedPresentationIsSkippedAsBusySurface() async {
        let analytics = AnalyticsLoggerSpy()
        let routable = RoutableSpy(isPresentationAllowed: false)
        let sut = makeSUT(analytics: analytics, routable: routable)
        #expect(await terminalState(of: sut) == .ready)

        let isPresented = await MainActor.run { sut.presentSheet(experimentVariant: "user_max_apy") != nil }
        sut.logShown()

        #expect(!isPresented)
        #expect(routable.presentedViewModel == nil)
        #expect(analytics.skipReasons == [.surfaceBusy])
        #expect(analytics.openedData.isEmpty)
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
        analytics: AnalyticsLoggerSpy = AnalyticsLoggerSpy(),
        routable: YieldModePromoSheetRoutable? = nil
    ) -> YieldModePromoSheetManager {
        let catalog = catalogPublisher ?? Just(makeCatalog(loadState)).eraseToAnyPublisher()
        let positions = positionsPublisher ?? Just([makePosition(yieldState: yieldState)]).eraseToAnyPublisher()

        return YieldModePromoSheetManager(
            catalogProvider: CatalogProviderStub(catalogPublisher: catalog),
            makePositionsProvider: { hasSelectedWallet ? PositionsProviderStub(positionsPublisher: positions) : nil },
            earnOffersLoader: earnLoader ?? EarnOffersLoaderSpy(result: .success(makeEarnResponse(total: 12))),
            analyticsLogger: analytics,
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

    func presentedAndLoggedData(variant: String, earnLoader: EarnOffersLoaderSpy? = nil) async -> [YieldModePromoSheetData?] {
        let analytics = AnalyticsLoggerSpy()
        let routable = RoutableSpy()
        let sut = makeSUT(earnLoader: earnLoader, analytics: analytics, routable: routable)
        _ = await terminalState(of: sut)

        let presented = await presentedData(of: sut, variant: variant, routable: routable)
        sut.logShown()

        return [presented, analytics.openedData.first]
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

    func makeEarnResponse(total: Int, topNetworkId: String = "ethereum") -> EarnDTO.List.Response {
        let items = total > 0
            ? [
                EarnDTO.List.Item(
                    apy: "0.092",
                    networkId: topNetworkId,
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

private final class AnalyticsLoggerSpy: YieldModePromoAnalyticsLogger {
    private let state = OSAllocatedUnfairLock(initialState: (openedData: [YieldModePromoSheetData](), skipReasons: [MainScreenPromoSheetSkipReason]()))

    var openedData: [YieldModePromoSheetData] {
        state.withLock { $0.openedData }
    }

    var skipReasons: [MainScreenPromoSheetSkipReason] {
        state.withLock { $0.skipReasons }
    }

    func logOpened(data: YieldModePromoSheetData) {
        state.withLock { $0.openedData.append(data) }
    }

    func logSkipped(reason: MainScreenPromoSheetSkipReason) {
        state.withLock { $0.skipReasons.append(reason) }
    }

    func logClosed(data: YieldModePromoSheetData, method: YieldModePromoCloseMethod) {}

    func logTryYieldMode(data: YieldModePromoSheetData) {}
}

private final class RoutableSpy: YieldModePromoSheetRoutable {
    private let isPresentationAllowed: Bool
    private(set) var presentedViewModel: YieldModePromoSheetViewModel?

    init(isPresentationAllowed: Bool = true) {
        self.isPresentationAllowed = isPresentationAllowed
    }

    func presentYieldModePromo(_ viewModel: YieldModePromoSheetViewModel) -> Bool {
        guard isPresentationAllowed else {
            return false
        }

        presentedViewModel = viewModel
        return true
    }

    func dismissYieldModePromo() {}

    func openYieldModeEarn() {}
}
