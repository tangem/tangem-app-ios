//
//  TokenSummaryViewModel.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemUI

@MainActor
final class TokenSummaryViewModel: ObservableObject, Identifiable {
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter

    let tokenName: String
    let networkName: String?
    let tokenIconInfo: TokenIconInfo

    @Published var selectedPeriod: TokenSummaryPeriod
    @Published private(set) var primaryAction: TokenSummaryPrimaryAction?
    @Published private(set) var isLoading = true
    @Published private(set) var gaugeState: TokenSummaryGaugeState = .dataUnavailable
    @Published private(set) var lastUpdated: Date?
    @Published private(set) var metrics: [TokenSummaryMetric] = []

    /// The coin-indicators contract carries no AI summary yet, so the block stays hidden until it does.
    let aiSummaryText: String? = nil

    private let symbol: String
    private let mapper: TokenSummaryIndicatorsMapper
    private let indicatorsProvider: TokenSummaryIndicatorsProvider
    private let primaryActionPublisher: AnyPublisher<TokenSummaryPrimaryAction?, Never>
    private let analyticsLogger: TokenSummaryAnalyticsLogger
    private var readings: [TokenSummaryIndicator] = []
    private var bag: Set<AnyCancellable> = []

    private let onPrimaryAction: (TokenSummaryPrimaryAction.Kind) -> Void
    private let onClose: () -> Void

    convenience init(
        tokenItem: TokenItem,
        period: TokenSummaryPeriod = .day,
        primaryActionPublisher: AnyPublisher<TokenSummaryPrimaryAction?, Never>,
        mapper: TokenSummaryIndicatorsMapper = TokenSummaryIndicatorsMapper(),
        indicatorsProvider: TokenSummaryIndicatorsProvider = CommonTokenSummaryIndicatorsProvider(),
        analyticsLogger: TokenSummaryAnalyticsLogger,
        onPrimaryAction: @escaping (TokenSummaryPrimaryAction.Kind) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.init(
            tokenName: tokenItem.name,
            networkName: tokenItem.networkName,
            tokenIconInfo: TokenIconInfoBuilder().build(from: tokenItem, isCustom: false),
            symbol: tokenItem.currencySymbol,
            period: period,
            primaryActionPublisher: primaryActionPublisher,
            mapper: mapper,
            indicatorsProvider: indicatorsProvider,
            analyticsLogger: analyticsLogger,
            onPrimaryAction: onPrimaryAction,
            onClose: onClose
        )

        analyticsLogger.logOpened()
        loadIndicators()
    }

    convenience init(
        coinName: String,
        symbol: String,
        tokenIconInfo: TokenIconInfo,
        period: TokenSummaryPeriod = .day,
        preloadedIndicators: [TokenSummaryIndicator]? = nil,
        primaryActionPublisher: AnyPublisher<TokenSummaryPrimaryAction?, Never>,
        mapper: TokenSummaryIndicatorsMapper = TokenSummaryIndicatorsMapper(),
        indicatorsProvider: TokenSummaryIndicatorsProvider = CommonTokenSummaryIndicatorsProvider(),
        analyticsLogger: TokenSummaryAnalyticsLogger,
        onPrimaryAction: @escaping (TokenSummaryPrimaryAction.Kind) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.init(
            tokenName: coinName,
            networkName: nil,
            tokenIconInfo: tokenIconInfo,
            symbol: symbol,
            period: period,
            primaryActionPublisher: primaryActionPublisher,
            mapper: mapper,
            indicatorsProvider: indicatorsProvider,
            analyticsLogger: analyticsLogger,
            onPrimaryAction: onPrimaryAction,
            onClose: onClose
        )

        analyticsLogger.logOpened()

        if let preloadedIndicators {
            apply(readings: preloadedIndicators)
        } else {
            loadIndicators()
        }
    }

    private init(
        tokenName: String,
        networkName: String?,
        tokenIconInfo: TokenIconInfo,
        symbol: String,
        period: TokenSummaryPeriod,
        primaryActionPublisher: AnyPublisher<TokenSummaryPrimaryAction?, Never>,
        mapper: TokenSummaryIndicatorsMapper,
        indicatorsProvider: TokenSummaryIndicatorsProvider,
        analyticsLogger: TokenSummaryAnalyticsLogger,
        onPrimaryAction: @escaping (TokenSummaryPrimaryAction.Kind) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.tokenName = tokenName
        self.networkName = networkName
        self.tokenIconInfo = tokenIconInfo
        self.primaryActionPublisher = primaryActionPublisher
        self.symbol = symbol
        selectedPeriod = period
        self.mapper = mapper
        self.indicatorsProvider = indicatorsProvider
        self.analyticsLogger = analyticsLogger
        self.onPrimaryAction = onPrimaryAction
        self.onClose = onClose

        bind()
    }

    func primaryActionTapped() {
        guard let primaryAction, primaryAction.isEnabled else {
            return
        }

        analyticsLogger.logPrimaryAction(kind: primaryAction.kind)
        onPrimaryAction(primaryAction.kind)
    }

    func closeTapped() {
        onClose()
    }

    func metricInfoTapped(_ metric: TokenSummaryMetric) {
        analyticsLogger.logIndicatorInfo(kind: metric.kind)

        let infoViewModel = TokenSummaryMetricInfoViewModel(
            title: metric.title,
            info: metric.info,
            onClose: { [weak self] in
                self?.floatingSheetPresenter.removeActiveSheet()
            }
        )

        floatingSheetPresenter.enqueue(sheet: infoViewModel)
    }

    private func bind() {
        $selectedPeriod
            .sink { [weak self] period in
                self?.updateDerivedState(for: period)
            }
            .store(in: &bag)

        // `dropFirst` skips the initial period so only user-driven changes are reported.
        $selectedPeriod
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] period in
                self?.analyticsLogger.logInterval(period: period)
            }
            .store(in: &bag)

        primaryActionPublisher
            .receiveOnMain()
            .removeDuplicates()
            .sink { [weak self] primaryAction in
                self?.primaryAction = primaryAction
            }
            .store(in: &bag)
    }

    private func loadIndicators() {
        Task { [weak self] in
            guard let self else { return }

            let loaded: [TokenSummaryIndicator]

            do {
                loaded = try await indicatorsProvider.loadIndicators(symbol: symbol)
            } catch {
                loaded = []
            }

            apply(readings: loaded)
        }
    }

    private func apply(readings: [TokenSummaryIndicator]) {
        self.readings = readings
        isLoading = false
        updateDerivedState(for: selectedPeriod)
    }

    private func updateDerivedState(for period: TokenSummaryPeriod) {
        let result = mapper.map(readings: readings, timeframe: period.timeframe)
        metrics = result.metrics
        lastUpdated = result.lastUpdated
        gaugeState = result.gaugeState
    }
}

// MARK: - Mock

extension TokenSummaryViewModel {
    static func mock(
        tokenItem: TokenItem,
        primaryAction: TokenSummaryPrimaryAction? = .goToSwap(isEnabled: true),
        onPrimaryAction: @escaping (TokenSummaryPrimaryAction.Kind) -> Void = { _ in },
        onClose: @escaping () -> Void = {}
    ) -> TokenSummaryViewModel {
        let viewModel = TokenSummaryViewModel(
            tokenName: tokenItem.name,
            networkName: tokenItem.networkName,
            tokenIconInfo: TokenIconInfoBuilder().build(from: tokenItem, isCustom: false),
            symbol: tokenItem.currencySymbol,
            period: .day,
            primaryActionPublisher: Just(primaryAction).eraseToAnyPublisher(),
            mapper: TokenSummaryIndicatorsMapper(),
            indicatorsProvider: StubTokenSummaryIndicatorsProvider(),
            analyticsLogger: TokenSummaryAnalyticsLoggerStub(),
            onPrimaryAction: onPrimaryAction,
            onClose: onClose
        )

        viewModel.readings = mockReadings
        viewModel.isLoading = false
        viewModel.updateDerivedState(for: viewModel.selectedPeriod)

        return viewModel
    }

    private static var mockReadings: [TokenSummaryIndicator] {
        [
            .init(kind: .galaxyScore, timeframe: nil, value: 72, signal: .neutral, subLabel: nil, updatedAt: nil),
            .init(kind: .sentiment, timeframe: nil, value: nil, signal: .unavailable, subLabel: nil, updatedAt: nil),
            .init(kind: .rsi, timeframe: .day, value: 61, signal: .bearish, subLabel: nil, updatedAt: nil),
            .init(kind: .macd, timeframe: .day, value: Decimal(string: "145.67"), signal: .bearish, subLabel: nil, updatedAt: nil),
            .init(kind: .maCross, timeframe: nil, value: 50, signal: .bearish, subLabel: nil, updatedAt: nil),
        ]
    }
}

private struct StubTokenSummaryIndicatorsProvider: TokenSummaryIndicatorsProvider {
    func loadIndicators(symbol: String) async throws -> [TokenSummaryIndicator] { [] }
}
