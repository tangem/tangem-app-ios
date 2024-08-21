//
//  MarketsItemViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class MarketsItemViewModel: Identifiable, ObservableObject {
    @Injected(\.quotesRepository) private var quotesRepository: TokenQuotesRepository

    // MARK: - Published

    @Published var priceValue: String = ""
    @Published var priceChangeState: TokenPriceChangeView.State = .empty
    // Charts will be implement in [REDACTED_INFO]
    @Published var charts: [Double]? = nil

    var marketRating: String?
    var marketCap: String?

    // MARK: - Properties

    let id: String
    let imageURL: URL?
    let name: String
    let symbol: String
    let didTapAction: () -> Void

    // MARK: - Private Properties

    private weak var filterProvider: MarketsListDataFilterProvider?

    private var bag = Set<AnyCancellable>()

    private let priceChangeUtility = PriceChangeUtility()
    private let priceFormatter = CommonTokenPriceFormatter()
    private let marketCapFormatter = MarketCapFormatter()

    // MARK: - Init

    init(_ data: InputData, chartsProvider: MarketsListChartsHistoryProvider, filterProvider: MarketsListDataFilterProvider) {
        id = data.id
        imageURL = IconURLBuilder().tokenIconURL(id: id, size: .large)
        name = data.name
        symbol = data.symbol.uppercased()
        didTapAction = data.didTapAction

        if let marketRating = data.marketRating {
            self.marketRating = "\(marketRating)"
        }

        if let marketCap = data.marketCap {
            self.marketCap = marketCapFormatter.formatDecimal(Decimal(marketCap))
        }

        setupPriceInfo(price: data.priceValue, priceChangeValue: data.priceChangeStateValue)
        bindToQuotesUpdates()

        self.filterProvider = filterProvider
        bindWithProviders(charts: chartsProvider, filter: filterProvider)
    }

    // MARK: - Private Implementation

    private func setupPriceInfo(price: Decimal?, priceChangeValue: Decimal?) {
        priceValue = priceFormatter.formatFiatBalance(price)
        priceChangeState = priceChangeUtility.convertToPriceChangeState(changePercent: priceChangeValue)
    }

    private func bindToQuotesUpdates() {
        quotesRepository.quotesPublisher
            .withWeakCaptureOf(self)
            .compactMap { viewModel, quotes in
                quotes[viewModel.id]
            }
            .withWeakCaptureOf(self)
            .sink { viewModel, quoteInfo in
                let priceChangeValue: Decimal?
                switch viewModel.filterProvider?.currentFilterValue.interval {
                case .day:
                    priceChangeValue = quoteInfo.priceChange24h
                case .week:
                    priceChangeValue = quoteInfo.priceChange7d
                case .month:
                    priceChangeValue = quoteInfo.priceChange30d
                default:
                    priceChangeValue = nil
                }
                viewModel.setupPriceInfo(price: quoteInfo.price, priceChangeValue: priceChangeValue)
            }
            .store(in: &bag)
    }

    private func bindWithProviders(charts: MarketsListChartsHistoryProvider, filter: MarketsListDataFilterProvider) {
        charts
            .$items
            .receive(on: DispatchQueue.main)
            .delay(for: 0.3, scheduler: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink(receiveValue: { viewModel, charts in
                guard let chart = charts.first(where: { $0.key == viewModel.id }) else {
                    return
                }

                let chartsDoubleConvertedValues = viewModel.mapHistoryPreviewItemModelToChartsList(chart.value[filter.currentFilterValue.interval])
                viewModel.charts = chartsDoubleConvertedValues
            })
            .store(in: &bag)
    }

    private func mapHistoryPreviewItemModelToChartsList(_ chartPreviewItem: MarketsChartsHistoryItemModel?) -> [Double]? {
        guard let chartPreviewItem else { return nil }

        let chartsDecimalValues: [Decimal] = chartPreviewItem.prices.values.map { $0 }
        let chartsDoubleConvertedValues: [Double] = chartsDecimalValues.map { NSDecimalNumber(decimal: $0).doubleValue }
        return chartsDoubleConvertedValues
    }
}

extension MarketsItemViewModel {
    struct InputData {
        let id: String
        let name: String
        let symbol: String
        let marketCap: UInt64?
        let marketRating: Int?
        let priceValue: Decimal?
        let priceChangeStateValue: Decimal?
        let didTapAction: () -> Void
    }
}
