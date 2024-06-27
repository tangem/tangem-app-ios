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

    var marketRating: String?
    var marketCap: String?

    var priceValue: String
    var priceChangeState: TokenPriceChangeView.State

    // Charts will be implement in [REDACTED_INFO]
    @Published var charts: [Double]? = nil

    // MARK: - Properties

    let id: String
    let imageURL: URL?
    let name: String
    let symbol: String
    let didTapAction: () -> Void

    // MARK: - Private Properties

    private var bag = Set<AnyCancellable>()

    private let priceChangeUtility = PriceChangeUtility()
    private let priceFormatter = CommonTokenPriceFormatter()
    private let marketCapFormatter = MarketCapFormatter()

    // MARK: - Init

    init(_ data: InputData) {
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

        priceValue = priceFormatter.formatFiatBalance(data.priceValue)
        priceChangeState = priceChangeUtility.convertToPriceChangeState(changePercent: data.priceChangeStateValue)

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
        let name: String
        let symbol: String
        let marketCap: UInt64?
        let marketRating: Int?
        let priceValue: Decimal?
        let priceChangeStateValue: Decimal?
        let didTapAction: () -> Void
    }

    enum Constants {
        static let priceChangeStateValueDevider: Decimal = 0.01
    }
}
