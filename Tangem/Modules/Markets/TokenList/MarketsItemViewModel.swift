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
    // MARK: - Injected Properties

    @Injected(\.quotesRepository) private var tokenQuotesRepository: TokenQuotesRepository

    // MARK: - Published

    @Published var marketRaiting: String = ""
    @Published var marketCap: String = ""

    @Published var priceValue: String = ""
    @Published var priceChangeState: TokenPriceChangeView.State = .noData
    @Published var priceHistory: [Double]? = nil

    @Published var isLoadingCharts: Bool

    // MARK: - Properties

    var id: String
    var imageURL: URL?
    var name: String
    var symbol: String

    // MARK: - Private Properties

    private var bag = Set<AnyCancellable>()

    private var priceChangeFormatter = PriceChangeFormatter()
    private let priceFormatter = CommonTokenPriceFormatter()

    // MARK: - Helpers

    var priceHistoryChangeType: ChangeSignType {
        guard
            let priceHistory,
            let firstValue = priceHistory.first,
            let lastValue = priceHistory.last
        else {
            return .positive
        }

        return ChangeSignType(from: Decimal(lastValue - firstValue))
    }

    // MARK: - Init

    init(_ data: InputData) {
        id = data.id
        imageURL = URL(string: data.imageURL)
        name = data.name
        symbol = data.symbol
        marketCap = data.marketCup
        marketRaiting = data.marketRaiting
        priceValue = priceFormatter.formatFiatBalance(data.priceValue)

        if let priceChangeResult = priceChangeFormatter.format(value: data.priceChangeStateValue) {
            priceChangeState = .loaded(signType: priceChangeResult.signType, text: priceChangeResult.formattedText)
        }

        isLoadingCharts = true

        bind()
    }

    // MARK: - Private Implementation

    private func bind() {
        // Need for user update charts
    }
}

extension MarketsItemViewModel {
    enum State {
        case loading
        case loaded
    }
}

extension MarketsItemViewModel {
    struct InputData {
        let id: String
        let imageURL: String
        let name: String
        let symbol: String
        let marketCup: String
        let marketRaiting: String
        let priceValue: Decimal
        let priceChangeStateValue: Decimal?
    }
}
