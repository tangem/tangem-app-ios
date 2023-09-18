//
//  ManageTokensItemViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class ManageTokensItemViewModel: Identifiable, ObservableObject {
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

    let id: UUID = .init()
    let imageURL: URL?
    let name: String
    let symbol: String
    let price: String
    let priceChange: TokenPriceChangeView.State
    let priceHistory: [Double]?
    let action: Action
    let didTapAction: (Action) -> Void

    init(
        imageURL: URL?,
        name: String,
        symbol: String,
        price: String,
        priceChange: TokenPriceChangeView.State,
        priceHistory: [Double]?,
        action: Action,
        didTapAction: @escaping (Action) -> Void
    ) {
        self.imageURL = imageURL
        self.name = name
        self.symbol = symbol
        self.price = price
        self.priceChange = priceChange
        self.priceHistory = priceHistory
        self.action = action
        self.didTapAction = didTapAction
    }
}

extension ManageTokensItemViewModel: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ManageTokensItemViewModel, rhs: ManageTokensItemViewModel) -> Bool {
        lhs.id == rhs.id
    }
}

extension ManageTokensItemViewModel {
    enum Action {
        case add
        case edit
        case info
    }
}
