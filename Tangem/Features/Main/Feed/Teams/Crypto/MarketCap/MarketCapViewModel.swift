//
//  MarketCapViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemFoundation
import TangemLocalization
import TangemUI

final class MarketCapViewModel: ObservableObject {
    @Published private(set) var state: State = .loading

    private let indicatorsProvider: MarketIndicatorsProvider
    private let priceChangeUtility = PriceChangeUtility()
    private let router: any CryptoFeedRoutable
    private let now: () -> Date

    private var marketCapFormatter: MarketCapFormatter
    private var loadingTask: Task<Void, Never>?
    private var loadState: LoadState = .idle
    private var bag = Set<AnyCancellable>()

    init(
        router: any CryptoFeedRoutable,
        indicatorsProvider: MarketIndicatorsProvider = InjectedValues[\.marketIndicatorsProvider],
        now: @escaping () -> Date = Date.init
    ) {
        self.router = router
        self.indicatorsProvider = indicatorsProvider
        self.now = now
        marketCapFormatter = Self.makeFormatter(currencyCode: AppSettings.shared.selectedCurrencyCode)

        bindToCurrencyCodeUpdate()
    }

    deinit {
        loadingTask?.cancel()
    }

    func onViewAppear() {
        loadIfNeeded()
    }

    func feedSheetSizeDidChange(to size: ShtorkaSize) {
        guard size != .collapsed else { return }

        loadIfNeeded()
    }

    func onInfoTap() {
        router.openMarketCapInfo(subject: .totalMarketCap)
    }

    func onMetricTap(_ metric: Metric) {
        router.openMarketCapInfo(subject: .index(metric))
    }
}

// MARK: - Loading

private extension MarketCapViewModel {
    func loadIfNeeded() {
        guard shouldLoad else { return }

        load(keepingContent: true)
    }

    var shouldLoad: Bool {
        switch loadState {
        case .idle: true
        case .loading: false
        case .loaded(let date): now().timeIntervalSince(date) >= Constants.readingLifetime
        }
    }

    func load(keepingContent: Bool) {
        loadingTask?.cancel()
        loadState = .loading

        if !keepingContent || !state.isContent {
            state = .loading
        }

        loadingTask = Task { @MainActor [weak self] in
            guard let self else { return }

            do {
                let indicators = try await indicatorsProvider.indicators(currency: AppSettings.shared.selectedCurrencyCode)
                try Task.checkCancellation()

                let loaded = makeState(for: indicators)
                loadState = loaded.isContent ? .loaded(now()) : .idle
                state = loaded
            } catch {
                guard !Task.isCancelled else { return }

                AppLogger.tag("Markets").error("Failed to load market indicators", error: error)

                loadState = .idle

                // A refresh that failed leaves the reading already on screen rather than emptying the block.
                guard !state.isContent else { return }

                state = .empty
            }
        }
    }

    func makeState(for indicators: MarketIndicators) -> State {
        guard let totalMarketCap = indicators.totalMarketCap, !totalMarketCap.isZero else {
            return .empty
        }

        let content = Content(
            totalMarketCap: marketCapFormatter.formatMarketCap(totalMarketCap),
            priceChange: priceChangeUtility.convertToPriceChangeState(changePercent: indicators.marketCapChangePercentage24h),
            metrics: [
                Metric(kind: .fearGreed, indicator: indicators.fearGreed),
                Metric(kind: .altcoinIndex, indicator: indicators.altcoinIndex),
            ].compactMap { $0 }
        )

        return .content(content)
    }

    func bindToCurrencyCodeUpdate() {
        AppSettings.shared.$selectedCurrencyCode
            .dropFirst()
            .withWeakCaptureOf(self)
            .sink { viewModel, currencyCode in
                viewModel.marketCapFormatter = Self.makeFormatter(currencyCode: currencyCode)
                viewModel.load(keepingContent: false)
            }
            .store(in: &bag)
    }

    static func makeFormatter(currencyCode: String) -> MarketCapFormatter {
        MarketCapFormatter(
            divisorsList: AmountNotationSuffixFormatter.Divisor.defaultList,
            baseCurrencyCode: currencyCode,
            notationFormatter: DefaultAmountNotationFormatter()
        )
    }
}

// MARK: - Load state

private extension MarketCapViewModel {
    enum LoadState {
        case idle
        case loading
        case loaded(Date)
    }
}

// MARK: - State

extension MarketCapViewModel {
    enum State {
        case loading
        case empty
        case content(Content)

        var isContent: Bool {
            if case .content = self {
                return true
            }

            return false
        }
    }

    struct Content {
        let totalMarketCap: String
        let priceChange: PriceChangeView.State
        let metrics: [Metric]

        static let placeholder = Content(
            totalMarketCap: "",
            priceChange: .loading,
            metrics: [Metric(kind: .fearGreed), Metric(kind: .altcoinIndex)]
        )
    }
}

// MARK: - Metric

extension MarketCapViewModel {
    struct Metric: Identifiable {
        enum Kind: String {
            case fearGreed
            case altcoinIndex

            var title: String {
                switch self {
                case .fearGreed: Localization.marketCryptoTotalCapFearGreedTitleShort
                case .altcoinIndex: Localization.marketCryptoTotalCapAltcoinIndexTitle
                }
            }

            var fullTitle: String {
                switch self {
                case .fearGreed: Localization.marketCryptoTotalCapFearGreedTitleFull
                case .altcoinIndex: Localization.marketCryptoTotalCapAltcoinIndexTitle
                }
            }

            var info: String {
                switch self {
                case .fearGreed: Localization.marketCryptoTotalCapFearGreedInfo
                case .altcoinIndex: Localization.marketCryptoTotalCapAltcoinIndexInfo
                }
            }
        }

        enum Appearance {
            case red
            case yellow
            case green
            case blue
        }

        var id: String { kind.rawValue }

        let kind: Kind
        let status: String
        let value: String
        let appearance: Appearance
        let progress: CGFloat

        var title: String { kind.title }

        init?(kind: Kind, indicator: MarketIndicators.Indicator?) {
            guard let indicator, let status = indicator.classification else {
                return nil
            }

            let rawValue = (indicator.value as NSDecimalNumber).doubleValue
            let position = min(max(rawValue, Constants.scale.lowerBound), Constants.scale.upperBound)

            self.kind = kind
            self.status = status
            value = String(Int(position.rounded()))
            progress = CGFloat((position - Constants.scale.lowerBound) / (Constants.scale.upperBound - Constants.scale.lowerBound))
            appearance = Appearance(position: position)
        }

        fileprivate init(kind: Kind) {
            self.kind = kind
            status = ""
            value = ""
            appearance = .red
            progress = 0
        }
    }
}

// MARK: - Appearance

private extension MarketCapViewModel.Metric.Appearance {
    init(position: Double) {
        switch position {
        case ...Constants.redBandUpperBound: self = .red
        case ...Constants.yellowBandUpperBound: self = .yellow
        case ...Constants.greenBandUpperBound: self = .green
        default: self = .blue
        }
    }

    /// Bands the design assigns to the scale, cut where Android cuts them.
    enum Constants {
        static let redBandUpperBound: Double = 33
        static let yellowBandUpperBound: Double = 49
        static let greenBandUpperBound: Double = 66
    }
}

// MARK: - Constants

private extension MarketCapViewModel {
    enum Constants {
        /// How often the backend refreshes the indicators.
        static let readingLifetime: TimeInterval = 15 * 60
    }
}

private extension MarketCapViewModel.Metric {
    enum Constants {
        static let scale: ClosedRange<Double> = 0 ... 100
    }
}
