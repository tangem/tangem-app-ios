//
//  MarketsPortfolioFlowViewModel.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import protocol TangemUI.FloatingSheetContentViewModel

@MainActor
final class MarketsPortfolioFlowViewModel: ObservableObject, FloatingSheetContentViewModel {
    @Published private(set) var state: State

    init(portfolioViewModel: MarketsPortfolioTokenListViewModel) {
        state = .portfolio(portfolioViewModel)
    }

    func showAddToken(_ viewModel: AddTokenFlowRedesignedViewModel) {
        state = .addToken(viewModel)
    }

    func showAddFunds(_ viewModel: AddFundsViewModel) {
        state = .addFunds(viewModel)
    }
}

// MARK: - State

extension MarketsPortfolioFlowViewModel {
    enum State {
        case portfolio(MarketsPortfolioTokenListViewModel)
        case addToken(AddTokenFlowRedesignedViewModel)
        case addFunds(AddFundsViewModel)

        var id: String {
            switch self {
            case .portfolio: return "portfolio"
            case .addToken: return "addToken"
            case .addFunds: return "addFunds"
            }
        }
    }
}
