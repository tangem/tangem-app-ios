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
    let networkName: String
    let tokenIconInfo: TokenIconInfo

    @Published var selectedPeriod: TokenSummaryPeriod
    @Published private(set) var canGoToSwap = false
    @Published private(set) var isLoading = true
    @Published private(set) var gaugeState: TokenSummaryGaugeState = .dataUnavailable
    @Published private(set) var lastUpdated: Date?
    @Published private(set) var metrics: [TokenSummaryMetric] = []

    /// The coin-indicators contract carries no AI summary yet, so the block stays hidden until it does.
    let aiSummaryText: String? = nil

    private let symbol: String
    private let mapper: TokenSummaryIndicatorsMapper
    private let indicatorsProvider: TokenSummaryIndicatorsProvider
    private let canGoToSwapPublisher: AnyPublisher<Bool, Never>
    private var readings: [TokenSummaryIndicator] = []
    private var bag: Set<AnyCancellable> = []

    private let onGoToSwap: () -> Void
    private let onClose: () -> Void

    convenience init(
        tokenItem: TokenItem,
        period: TokenSummaryPeriod = .day,
        canGoToSwapPublisher: AnyPublisher<Bool, Never>,
        mapper: TokenSummaryIndicatorsMapper = TokenSummaryIndicatorsMapper(),
        indicatorsProvider: TokenSummaryIndicatorsProvider = CommonTokenSummaryIndicatorsProvider(),
        onGoToSwap: @escaping () -> Void,
        onClose: @escaping () -> Void
    ) {
        self.init(
            tokenName: tokenItem.name,
            networkName: tokenItem.networkName,
            tokenIconInfo: TokenIconInfoBuilder().build(from: tokenItem, isCustom: false),
            symbol: tokenItem.currencySymbol,
            period: period,
            canGoToSwapPublisher: canGoToSwapPublisher,
            mapper: mapper,
            indicatorsProvider: indicatorsProvider,
            onGoToSwap: onGoToSwap,
            onClose: onClose
        )

        loadIndicators()
    }

    private init(
        tokenName: String,
        networkName: String,
        tokenIconInfo: TokenIconInfo,
        symbol: String,
        period: TokenSummaryPeriod,
        canGoToSwapPublisher: AnyPublisher<Bool, Never>,
        mapper: TokenSummaryIndicatorsMapper,
        indicatorsProvider: TokenSummaryIndicatorsProvider,
        onGoToSwap: @escaping () -> Void,
        onClose: @escaping () -> Void
    ) {
        self.tokenName = tokenName
        self.networkName = networkName
        self.tokenIconInfo = tokenIconInfo
        self.canGoToSwapPublisher = canGoToSwapPublisher
        self.symbol = symbol
        selectedPeriod = period
        self.mapper = mapper
        self.indicatorsProvider = indicatorsProvider
        self.onGoToSwap = onGoToSwap
        self.onClose = onClose

        bind()
    }

    func goToSwapTapped() {
        onGoToSwap()
    }

    func closeTapped() {
        onClose()
    }

    func metricInfoTapped(_ metric: TokenSummaryMetric) {
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

        canGoToSwapPublisher
            .receiveOnMain()
            .removeDuplicates()
            .sink { [weak self] canGoToSwap in
                self?.canGoToSwap = canGoToSwap
            }
            .store(in: &bag)
    }

    private func loadIndicators() {
        Task { [weak self] in
            guard let self else { return }

            do {
                readings = try await indicatorsProvider.loadIndicators(symbol: symbol)
            } catch {
                readings = []
            }

            isLoading = false
            updateDerivedState(for: selectedPeriod)
        }
    }

    private func updateDerivedState(for period: TokenSummaryPeriod) {
        let result = mapper.map(readings: readings, timeframe: period.timeframe)
        metrics = result.metrics
        lastUpdated = result.lastUpdated

        if let score = result.score {
            gaugeState = .score(score)
        } else {
            gaugeState = result.metrics.isEmpty ? .dataUnavailable : .outlookUnavailable
        }
    }
}

// MARK: - Mock

extension TokenSummaryViewModel {
    static func mock(
        tokenItem: TokenItem,
        onGoToSwap: @escaping () -> Void = {},
        onClose: @escaping () -> Void = {}
    ) -> TokenSummaryViewModel {
        let viewModel = TokenSummaryViewModel(
            tokenName: tokenItem.name,
            networkName: tokenItem.networkName,
            tokenIconInfo: TokenIconInfoBuilder().build(from: tokenItem, isCustom: false),
            symbol: tokenItem.currencySymbol,
            period: .day,
            canGoToSwapPublisher: Just(true).eraseToAnyPublisher(),
            mapper: TokenSummaryIndicatorsMapper(),
            indicatorsProvider: StubTokenSummaryIndicatorsProvider(),
            onGoToSwap: onGoToSwap,
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
