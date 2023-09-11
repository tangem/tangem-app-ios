//
//  LegacyCoinViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class CoinViewModel: Identifiable, ObservableObject {
    let id: UUID = .init()
    let imageURL: URL?
    let name: String
    let symbol: String

    let price: String
    let priceChange: TokenPriceChangeView.State

    let priceHistory: [Double]?
    var priceHistoryChangeType: TokenPriceChangeView.ChangeSignType {
        guard
            let priceHistory,
            let firstValue = priceHistory.first,
            let lastValue = priceHistory.last
        else {
            return .same
        }

        if lastValue >= firstValue {
            return .positive
        } else {
            return .negative
        }
    }

    let manageType: CoinViewManageButtonType

    let didTapAction: (CoinViewManageButtonType) -> Void

    init(imageURL: URL?, name: String, symbol: String, price: String, priceChange: TokenPriceChangeView.State, priceHistory: [Double]?, manageType: CoinViewManageButtonType, didTapAction: @escaping (CoinViewManageButtonType) -> Void) {
        self.imageURL = imageURL
        self.name = name
        self.symbol = symbol
        self.price = price
        self.priceChange = priceChange
        self.priceHistory = priceHistory
        self.manageType = manageType
        self.didTapAction = didTapAction
    }
}

extension CoinViewModel: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: CoinViewModel, rhs: CoinViewModel) -> Bool {
        lhs.id == rhs.id
    }
}
