//
//  MarketsAddTokenView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemLocalization

struct MarketsTokenAccountNetworkSelectorFlowView: View {
    @ObservedObject var viewModel: MarketsTokenAccountNetworkSelectorFlowViewModel

    var body: some View {
        contentView
            .animation(.contentFrameUpdate, value: viewModel.viewState)
    }

    private var contentView: some View {
        ZStack {
            switch viewModel.viewState {
            case .accountSelector(let accountSelectorViewModel, _):
                AccountSelectorView(viewModel: accountSelectorViewModel)
                    .transition(.content)

            case .networksSelection(let marketsNetworkSelectorViewModel, _):
                MarketsNetworkSelectorView(viewModel: marketsNetworkSelectorViewModel)
                    .transition(.content)

            case .addToken(let addTokenViewModel):
                MarketsAddTokenView(viewModel: addTokenViewModel)
                    .transition(.content)

            case .getToken(let getTokenViewModel):
                MarketsGetTokenView(viewModel: getTokenViewModel)
                    .transition(.content)
            }
        }
        .safeAreaInset(edge: .top, spacing: .zero) {
            header(from: viewModel.viewState)
        }
        .scrollBounceBehavior(.basedOnSize)
        .coordinateSpace(name: Layout.scrollViewCoordinateSpace)
        .floatingSheetConfiguration { configuration in
            configuration.sheetFrameUpdateAnimation = .contentFrameUpdate
            configuration.backgroundInteractionBehavior = .consumeTouches
        }
    }

    private func header(from viewState: MarketsTokenAccountNetworkSelectorFlowViewModel.ViewState) -> some View {
        let title: String
        let backButtonAction = viewState.canGoBack ? { viewModel.back() } : nil
        let closeButtonAction = viewState.canBeClosed ? { viewModel.close() } : nil

        switch viewState {
        case .accountSelector:
            title = Localization.commonChooseAccount

        case .networksSelection:
            title = Localization.commonChooseNetwork

        case .addToken:
            title = Localization.commonAddToken

        case .getToken:
            title = Localization.commonGetToken
        }

        return FloatingSheetNavigationBarView(
            title: title,
            backgroundColor: Colors.Background.tertiary,
            backButtonAction: backButtonAction,
            closeButtonAction: closeButtonAction
        )
        .id(viewState.id)
        .transition(.opacity)
        .transformEffect(.identity)
        .animation(.headerOpacity.delay(0.2), value: viewState)
    }
}

private extension Animation {
    static let headerOpacity = Animation.curve(.easeOutStandard, duration: 0.2)
    static let contentFrameUpdate = Animation.curve(.easeInOutRefined, duration: 0.5)
}

private extension AnyTransition {
    static let content = AnyTransition.asymmetric(
        insertion: .opacity.animation(.curve(.easeInOutRefined, duration: 0.3).delay(0.2)),
        removal: .opacity.animation(.curve(.easeInOutRefined, duration: 0.3))
    )
}

extension MarketsTokenAccountNetworkSelectorFlowView {
    private enum Layout {
        static let scrollViewCoordinateSpace = "MarketsTokenAccountNetworkSelectorFlowView.ScrollView"
    }
}
