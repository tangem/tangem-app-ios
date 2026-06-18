//
//  MarketsPortfolioFlowView.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct MarketsPortfolioFlowView: View {
    @ObservedObject var viewModel: MarketsPortfolioFlowViewModel

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .portfolio(let portfolioViewModel):
                MarketsPortfolioTokenListView(viewModel: portfolioViewModel)
                    .transition(.content)

            case .addToken(let addTokenViewModel):
                AddTokenFlowRedesignedView(viewModel: addTokenViewModel)
                    .transition(.content)

            case .addFunds(let addFundsViewModel):
                AddFundsView(viewModel: addFundsViewModel)
                    .transition(.content)
            }
        }
        .animation(.contentFrameUpdate, value: viewModel.state.id)
        .floatingSheetConfiguration { configuration in
            configuration.sheetFrameUpdateAnimation = .contentFrameUpdate
            configuration.backgroundInteractionBehavior = .consumeTouches
            configuration.sheetBackgroundColor = Color.Tangem.Surface.level2
        }
    }
}

// MARK: - Animations

private extension Animation {
    static let contentFrameUpdate = Animation.curve(.easeInOutRefined, duration: 0.5)
}

private extension AnyTransition {
    static let content = AnyTransition.asymmetric(
        insertion: .opacity.animation(.curve(.easeInOutRefined, duration: 0.3).delay(0.2)),
        removal: .opacity.animation(.curve(.easeInOutRefined, duration: 0.3))
    )
}
