//
//  ManageTokensItemViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class ManageTokensItemViewModel: Identifiable, ObservableObject {
    // MARK: - Injected Properties

    @Injected(\.tokenQuotesRepository) private var tokenQuotesRepository: TokenQuotesRepository

    // MARK: - Published

    @Published var priceValue: String = ""
    @Published var priceChangeState: TokenPriceChangeView.State = .noData
    @Published var priceHistory: [Double]? = nil

    // MARK: - Properties

    var id: String { coin.id }
    var imageURL: URL? { TokenIconURLBuilder().iconURL(id: coin.id, size: .large) }
    var name: String { coin.name }
    var symbol: String { coin.symbol }

    let coin: CoinModel
    let action: Action
    let didTapAction: (Action, CoinModel) -> Void

    private var bag = Set<AnyCancellable>()

    private var percentFormatter = PercentFormatter()
    private var balanceFormatter = BalanceFormatter()

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

    init(
        coinModel: CoinModel,
        priceValue: String = "",
        priceChangeState: TokenPriceChangeView.State = .loading,
        priceHistory: [Double]? = nil,
        action: Action,
        didTapAction: @escaping (Action, CoinModel) -> Void
    ) {
        coin = coinModel
        self.priceValue = priceValue
        self.priceChangeState = priceChangeState
        self.priceHistory = nil
        self.action = action
        self.didTapAction = didTapAction
    }

    // MARK: - Public Implementation

    func updateQuote() {
        guard let quote = tokenQuotesRepository.quote(for: id) else {
            priceValue = ""
            priceChangeState = .noData
            return
        }

        priceChangeState = getPriceChangeState(by: quote)
        priceValue = balanceFormatter.formatFiatBalance(quote.price)
    }

    // MARK: - Private Implementation

    private func getPriceChangeState(by quote: TokenQuote) -> TokenPriceChangeView.State {
        let signType = ChangeSignType(from: quote.change)

        let percent = percentFormatter.percentFormat(value: quote.change)
        return .loaded(signType: signType, text: percent)
    }
}

extension ManageTokensItemViewModel {
    enum Action {
        case add
        case edit
        case info
    }
}
