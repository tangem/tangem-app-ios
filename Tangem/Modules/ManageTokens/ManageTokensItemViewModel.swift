//
//  ManageTokensItemViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class ManageTokensItemViewModel: Identifiable, ObservableObject {
    // MARK: - Published

    @Published var priceValue: String = ""
    @Published var priceChangeState: TokenPriceChangeView.State = .noData
    @Published var priceHistory: [Double]? = nil

    // MARK: - Properties

    let id: String
    let imageURL: URL?
    let name: String
    let symbol: String
    let action: Action
    let didTapAction: (Action, ID) -> Void

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
        id: String = UUID().uuidString,
        imageURL: URL?,
        name: String,
        symbol: String,
        priceValue: String = "",
        priceChangeState: TokenPriceChangeView.State,
        priceHistory: [Double]? = nil,
        action: Action,
        didTapAction: @escaping (Action, ID) -> Void
    ) {
        self.id = id
        self.imageURL = imageURL
        self.name = name
        self.symbol = symbol
        self.priceValue = priceValue
        self.priceChangeState = priceChangeState
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
