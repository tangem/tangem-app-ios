//
//  LendingPositionViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import Testing
import TangemFoundation
import TangemTestKit
@testable import BlockchainSdk
@testable import Tangem

@Suite("Lending position", .timeLimit(.minutes(1)))
@MainActor
final class LendingPositionViewModelTests: LeakTrackingTestSuite {
    private static let tokenItem = TokenItem.blockchain(.init(.ethereum(testnet: false), derivationPath: nil))

    @Test("Shows the supplied ETH, its fiat value and how much of it Aave can pay out now")
    func positionIsShown() async {
        let sut = makeSUT(position: .success(2), available: .success(Decimal(15) / 10), fiat: 4000)

        sut.onAppear()
        await sut.positionTask?.value

        let formatter = BalanceFormatter()
        #expect(sut.state.balance == LendingPositionContentView.StateModel.Balance(
            fiat: formatter.formatFiatBalance(4000, currencyCode: "USD"),
            crypto: formatter.formatCryptoBalance(2, currencyCode: "ETH")
        ))
        #expect(sut.state.availableBalance == formatter.formatCryptoBalance(Decimal(15) / 10, currencyCode: "ETH"))
        #expect(sut.state.canWithdraw)
    }

    @Test("A failed liquidity read shows the whole position as available, as the PRD asks")
    func availableFallsBackToPosition() async {
        let sut = makeSUT(position: .success(2), available: .failure(StubError()))

        sut.onAppear()
        await sut.positionTask?.value

        #expect(sut.state.availableBalance == BalanceFormatter().formatCryptoBalance(2, currencyCode: "ETH"))
    }

    @Test("A failed position read shows no amounts and keeps Withdraw off")
    func failedPositionRead() async {
        let router = RouterSpy()
        let sut = makeSUT(position: .failure(StubError()), router: router)

        sut.onAppear()
        await sut.positionTask?.value
        sut.handle(.withdraw)

        #expect(sut.state.balance?.crypto == BalanceFormatter.defaultEmptyBalanceString)
        #expect(sut.state.availableBalance == BalanceFormatter.defaultEmptyBalanceString)
        #expect(!sut.state.canWithdraw)
        #expect(router.withdrawnPositions.isEmpty)
    }

    @Test("Coming back to the screen reads the position again")
    func reappearReloadsPosition() async {
        let liquidity = LiquidityProviderStub(position: .failure(StubError()), available: .success(2))
        let sut = makeSUT(liquidity: liquidity)
        sut.onAppear()
        await sut.positionTask?.value

        liquidity.position = .success(2)
        sut.onAppear()
        await sut.positionTask?.value

        #expect(sut.state.canWithdraw)
    }

    @Test("A failed re-read after a successful one turns Withdraw off and keeps the old position out of it")
    func failedReloadDisablesWithdraw() async {
        let liquidity = LiquidityProviderStub(position: .success(2), available: .success(2))
        let router = RouterSpy()
        let sut = makeSUT(liquidity: liquidity, router: router)
        sut.onAppear()
        await sut.positionTask?.value

        liquidity.position = .failure(StubError())
        sut.onAppear()
        await sut.positionTask?.value
        sut.handle(.withdraw)

        #expect(!sut.state.canWithdraw)
        #expect(router.withdrawnPositions.isEmpty)
    }

    @Test("While the position is read again Withdraw stays off, so it never opens with the old position")
    func reloadKeepsWithdrawOff() async {
        let router = RouterSpy()
        let sut = makeSUT(position: .success(2), router: router)
        sut.onAppear()
        await sut.positionTask?.value

        sut.onAppear()
        sut.handle(.withdraw)

        #expect(!sut.state.canWithdraw)
        #expect(router.withdrawnPositions.isEmpty)

        await sut.positionTask?.value

        #expect(sut.state.canWithdraw)
    }

    @Test("Withdraw opens the withdrawal with the loaded position and the amount available right now")
    func withdrawOpensWithPosition() async {
        let router = RouterSpy()
        let sut = makeSUT(position: .success(2), available: .success(Decimal(15) / 10), router: router)

        sut.onAppear()
        await sut.positionTask?.value
        sut.handle(.withdraw)

        #expect(router.withdrawnPositions == [2])
        #expect(router.withdrawnAvailable == [Decimal(15) / 10])
    }

    @Test("When the available amount couldn't be read, the withdrawal gets none and reads it itself")
    func withdrawWithoutAvailable() async {
        let router = RouterSpy()
        let sut = makeSUT(position: .success(2), available: .failure(StubError()), router: router)

        sut.onAppear()
        await sut.positionTask?.value
        sut.handle(.withdraw)

        #expect(router.withdrawnPositions == [2])
        #expect(router.withdrawnAvailable == [nil])
    }

    @Test("A confirmed transaction reads the position again, so a fresh deposit or withdrawal shows up")
    func confirmedTransactionReloadsPosition() async {
        let pending = CurrentValueSubject<[PendingTransactionRecord], Never>([Self.pendingTransaction])
        let liquidity = LiquidityProviderStub(position: .success(0), available: .success(0))
        let sut = makeSUT(liquidity: liquidity, pendingTransactions: pending.eraseToAnyPublisher())
        var reads = liquidity.positionReads.makeAsyncIterator()
        sut.onAppear()
        _ = await reads.next()
        await sut.positionTask?.value

        liquidity.position = .success(2)
        pending.send([])
        _ = await reads.next()
        await sut.positionTask?.value

        #expect(sut.state.canWithdraw)
    }

    @Test("Withdraw opens the withdrawal once and waits while the module is being read")
    func withdrawWaitsWhileLoading() async {
        let router = RouterSpy()
        let sut = makeSUT(position: .success(2), router: router)
        sut.onAppear()
        await sut.positionTask?.value

        sut.handle(.withdraw)
        sut.setWithdrawLoading(true)
        sut.handle(.withdraw)

        #expect(router.withdrawnPositions == [2])
        #expect(sut.state.isWithdrawLoading)
    }

    @Test(
        "While one button is reading the module, the other one does nothing",
        arguments: [(LendingPositionContentView.Action.withdraw, true), (.addFunds, false)]
    )
    func buttonsWaitForEachOther(tapped: LendingPositionContentView.Action, addFundsLoading: Bool) async {
        let router = RouterSpy()
        let sut = makeSUT(position: .success(2), router: router)
        sut.onAppear()
        await sut.positionTask?.value

        if addFundsLoading {
            sut.setAddFundsLoading(true)
        } else {
            sut.setWithdrawLoading(true)
        }

        sut.handle(tapped)

        #expect(router.withdrawnPositions.isEmpty)
        #expect(router.addFundsCount == 0)
    }

    @Test("Add funds opens the deposit once and waits while the module is being read")
    func addFundsWaitsWhileLoading() {
        let router = RouterSpy()
        let sut = makeSUT(router: router)

        sut.handle(.addFunds)
        sut.setAddFundsLoading(true)
        sut.handle(.addFunds)

        #expect(router.addFundsCount == 1)
        #expect(sut.state.isAddFundsLoading)
    }

    @Test("Without a current APY the calculator is off and the rate shows a dash")
    func unknownApy() {
        let sut = makeSUT(currentApy: nil)

        #expect(!sut.state.isApyKnown)
        #expect(sut.state.currentApy == BalanceFormatter.defaultEmptyBalanceString)
    }

    @Test("The balance info sheets name the performance fee and explain the liquidity limit")
    func balanceInfoSheets() {
        let sut = makeSUT()
        let fee = PercentFormatter().format(Decimal(15) / 100, option: .performanceFee)

        #expect(sut.state.totalBalanceInfo.title == "Total balance")
        #expect(sut.state.totalBalanceInfo.content == .text("Your ETH in Aave, including the yield it has earned, after the \(fee) performance fee. It grows automatically while your ETH is in Aave."))
        #expect(sut.state.availableBalanceInfo.title == "Available balance")
        #expect(sut.state.availableBalanceInfo.content == .text("The amount you can withdraw right now. It depends on the ETH available in Aave, so it can be lower than your total balance. You can withdraw the rest once liquidity returns."))
    }

    @Test("The chart opens on six months and reloads for the period the user picks")
    func periodSelectionReloadsChart() async {
        let history = ApyHistoryProviderSpy(result: .success(Self.chartData))
        let sut = makeSUT(history: history)

        sut.onAppear()
        await sut.chartTask?.value
        sut.handle(.selectPeriod(.oneMonth))
        await sut.chartTask?.value

        #expect(history.requestedPeriods == [.sixMonths, .oneMonth])
        #expect(sut.state.chart == .loaded(Self.chartData))
    }

    @Test("A slow chart for a period the user already left doesn't replace the new period's chart")
    func staleChartIsIgnored() async {
        let gate = TestGate()
        let history = ApyHistoryProviderSpy(result: .success(Self.chartData), gatedPeriod: .sixMonths, gate: gate)
        let sut = makeSUT(history: history)
        sut.onAppear()
        let slowLoad = sut.chartTask

        sut.handle(.selectPeriod(.oneMonth))
        await sut.chartTask?.value
        history.result = .success(Self.staleChartData)
        gate.open()
        await slowLoad?.value

        #expect(sut.state.chart == .loaded(Self.chartData))
    }

    @Test("A failed chart load offers a retry that loads it again")
    func chartRetry() async {
        let history = ApyHistoryProviderSpy(result: .failure(StubError()))
        let sut = makeSUT(history: history)
        sut.onAppear()
        await sut.chartTask?.value

        guard case .error(let retry) = sut.state.chart else {
            Issue.record("Expected the chart error state")
            return
        }

        history.result = .success(Self.chartData)
        await retry()
        await sut.chartTask?.value

        #expect(sut.state.chart == .loaded(Self.chartData))
    }
}

// MARK: - Helpers

private extension LendingPositionViewModelTests {
    nonisolated static let chartData = YieldChartData(buckets: [4, 5], averageApy: 4.5, maxApy: 5, xTicks: [0: "Oct", 1: "Nov"])
    nonisolated static let staleChartData = YieldChartData(buckets: [9], averageApy: 9, maxApy: 9, xTicks: [0: "May"])

    func makeSUT(
        position: Result<Decimal, Error> = .success(2),
        available: Result<Decimal, Error> = .success(2),
        liquidity: LiquidityProviderStub? = nil,
        currentApy: Decimal? = Decimal(string: "0.0449"),
        fiat: Decimal? = 4000,
        history: ApyHistoryProviderSpy = ApyHistoryProviderSpy(result: .success(LendingPositionViewModelTests.chartData)),
        pendingTransactions: AnyPublisher<[PendingTransactionRecord], Never> = .just(output: []),
        router: RouterSpy = RouterSpy()
    ) -> LendingPositionViewModel {
        let sut = LendingPositionViewModel(
            tokenItem: Self.tokenItem,
            currentApy: currentApy,
            performanceFee: Decimal(15) / 100,
            details: .preview,
            currencyCode: "USD",
            liquidityProvider: liquidity ?? LiquidityProviderStub(position: position, available: available),
            apyHistoryProvider: history,
            fiatConverter: { _ in fiat },
            pendingTransactions: pendingTransactions,
            router: router
        )

        return trackForMemoryLeaks(sut)
    }

    static let pendingTransaction = PendingTransactionRecord(
        hash: "0xPending",
        source: "0x2222222222222222222222222222222222222222",
        destination: "0x00000000000000000000000000000000000000a1",
        amount: Amount(with: .ethereum(testnet: false), type: .coin, value: 1),
        fee: Fee(Amount(with: .ethereum(testnet: false), type: .coin, value: Decimal(1) / 1000)),
        date: Date(),
        isIncoming: false,
        transactionType: .transfer,
        transactionParams: nil
    )
}

// MARK: - Stubs

private struct StubError: Error {}

private final class LiquidityProviderStub: YieldModuleLendingLiquidityProvider {
    private let state: OSAllocatedUnfairLock<(position: Result<Decimal, Error>, available: Result<Decimal, Error>)>

    let positionReads: AsyncStream<Void>
    private let positionReadsContinuation: AsyncStream<Void>.Continuation

    init(position: Result<Decimal, Error>, available: Result<Decimal, Error>) {
        state = OSAllocatedUnfairLock(initialState: (position, available))
        (positionReads, positionReadsContinuation) = AsyncStream.makeStream()
    }

    var position: Result<Decimal, Error> {
        get { state.withLock { $0.position } }
        set { state.withLock { $0.position = newValue } }
    }

    func wrappedNative() async throws -> String {
        "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"
    }

    func nativePosition() async throws -> Decimal {
        defer { positionReadsContinuation.yield() }
        return try state.withLock { $0.position }.get()
    }

    func availableToWithdraw(nativePosition: Decimal) async throws -> Decimal {
        try state.withLock { $0.available }.get()
    }
}

private final class ApyHistoryProviderSpy: LendingApyHistoryProvider {
    private struct State {
        var result: Result<YieldChartData, Error>
        var requestedPeriods: [LendingApyHistoryPeriod] = []
    }

    private let state: OSAllocatedUnfairLock<State>
    private let gatedPeriod: LendingApyHistoryPeriod?
    private let gate: TestGate?

    init(result: Result<YieldChartData, Error>, gatedPeriod: LendingApyHistoryPeriod? = nil, gate: TestGate? = nil) {
        state = OSAllocatedUnfairLock(initialState: State(result: result))
        self.gatedPeriod = gatedPeriod
        self.gate = gate
    }

    var result: Result<YieldChartData, Error> {
        get { state.withLock { $0.result } }
        set { state.withLock { $0.result = newValue } }
    }

    var requestedPeriods: [LendingApyHistoryPeriod] {
        state.withLock { $0.requestedPeriods }
    }

    func history(for period: LendingApyHistoryPeriod) async throws -> YieldChartData {
        state.withLock { $0.requestedPeriods.append(period) }

        if period == gatedPeriod {
            await gate?.wait()
        }

        return try state.withLock { $0.result }.get()
    }
}

private final class RouterSpy: LendingPositionRoutable {
    private let state = OSAllocatedUnfairLock(initialState: (withdrawals: [(position: Decimal, available: Decimal?)](), addFundsCount: 0))

    var withdrawnPositions: [Decimal] {
        state.withLock { $0.withdrawals.map(\.position) }
    }

    var withdrawnAvailable: [Decimal?] {
        state.withLock { $0.withdrawals.map(\.available) }
    }

    var addFundsCount: Int {
        state.withLock { $0.addFundsCount }
    }

    func openWithdraw(position: Decimal, available: Decimal?) {
        state.withLock { $0.withdrawals.append((position, available)) }
    }

    func openAddFunds() {
        state.withLock { $0.addFundsCount += 1 }
    }

    func openHowItWorks() {}
    func openURL(_ url: URL) {}
    func closeLendingPosition() {}
}
