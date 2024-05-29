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

    @Published var isLoading: Bool

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
        imageURL = IconURLBuilder().tokenIconURL(id: data.id, size: .large)
        name = data.name
        symbol = data.symbol
        marketCap = data.marketCup
        marketRaiting = data.marketRaiting
        priceValue = data.priceValue
        priceChangeState = data.priceChangeState
        priceHistory = data.priceHistory

        isLoading = data.state == .loading

        bind()
    }

    // MARK: - Private Implementation

    private func bind() {
        tokenQuotesRepository.quotesPublisher.sink { [weak self] itemQuote in
            guard let self = self else { return }

            if let quote = itemQuote[id] {
                updateView(by: quote)
            }

            return
        }
        .store(in: &bag)
    }

    private func updateView(by quote: TokenQuote) {
        guard priceValue.isEmpty || priceChangeState == .loading || priceChangeState == .noData else {
            return
        }

        priceChangeState = getPriceChangeState(by: quote)
        priceValue = priceFormatter.formatFiatBalance(quote.price)

        priceHistory = quote.prices24h?.map { $0 }
    }

    private func getPriceChangeState(by quote: TokenQuote) -> TokenPriceChangeView.State {
        let change = quote.change ?? 0
        let result = priceChangeFormatter.format(value: change)
        return .loaded(signType: result.signType, text: result.formattedText)
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
        let name: String
        let symbol: String
        let marketCup: String
        let marketRaiting: String
        let priceValue: String
        let priceChangeState: TokenPriceChangeView.State
        let priceHistory: [Double]?
        let state: State

        init(
            token: MarketTokenModel,
            priceValue: String = "",
            priceChangeState: TokenPriceChangeView.State = .loading,
            priceHistory: [Double]? = nil,
            state: State
        ) {
            id = token.id
            name = token.name
            symbol = token.symbol
            marketCup = token.marketCup
            marketRaiting = token.marketRaiting
            self.priceValue = priceValue
            self.priceChangeState = priceChangeState
            self.priceHistory = priceHistory
            self.state = state
        }
    }
}
