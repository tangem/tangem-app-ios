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
    
    // MARK: - Published

    @Published var marketRaiting: String = ""
    @Published var marketCap: String = ""

    @Published var priceValue: String = ""
    @Published var priceChangeState: TokenPriceChangeView.State = .noData

    // Charts will be implement in [REDACTED_INFO]
    @Published var charts: [Double]? = nil

    // MARK: - Properties

    var id: String
    var imageURL: URL?
    var name: String
    var symbol: String

    // MARK: - Private Properties

    private var bag = Set<AnyCancellable>()

    private var priceChangeFormatter = PriceChangeFormatter()
    private let priceFormatter = CommonTokenPriceFormatter()

    // MARK: - Init

    init(_ data: InputData) {
        id = data.id
        imageURL = URL(string: data.imageURL)
        name = data.name
        symbol = data.symbol

        marketCap = data.marketCup
        marketRaiting = data.marketRaiting

        priceValue = priceFormatter.formatFiatBalance(data.priceValue)

        if let priceChangeStateValue = data.priceChangeStateValue {
            let priceChangeResult = priceChangeFormatter.format(value: priceChangeStateValue)
            priceChangeState = .loaded(signType: priceChangeResult.signType, text: priceChangeResult.formattedText)
        } else {
            priceChangeState = .loading
        }

        bind()
    }

    // MARK: - Private Implementation

    private func bind() {
        // Need for user update charts
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
        let priceValue: Decimal?
        let priceChangeStateValue: Decimal?
    }
}
