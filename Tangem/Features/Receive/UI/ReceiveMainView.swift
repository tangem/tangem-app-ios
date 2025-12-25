//
//  ReceiveMainView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemLocalization

struct ReceiveMainView: View {
    // MARK: - ViewModel

    @ObservedObject var viewModel: ReceiveMainViewModel

    var body: some View {
        contentView
            .animation(.contentFrameUpdate, value: viewModel.viewState)
    }

    @ViewBuilder
    private var contentView: some View {
        ZStack {
            switch viewModel.viewState {
            case .selector(let viewModel):
                SelectorReceiveAssetsView(viewModel: viewModel)
                    .transition(.content)
            case .qrCode(let viewModel):
                QRCodeReceiveAssetsView(viewModel: viewModel)
                    .transition(.content)
            case .tokenAlert(let viewModel):
                TokenAlertReceiveAssetsView(viewModel: viewModel)
            case .yieldTokenAlert(let viewModel):
                YieldNoticeReceiveView(viewModel: viewModel)
            case .none:
                EmptyView()
            }
        }
        .safeAreaInset(edge: .top, spacing: .zero) {
            if let viewState = viewModel.viewState {
                header(from: viewState)
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .coordinateSpace(name: Layout.scrollViewCoordinateSpace)
        .floatingSheetConfiguration { configuration in
            configuration.sheetBackgroundColor = viewModel.viewState?.backgroundColor ?? Colors.Background.tertiary
            configuration.sheetFrameUpdateAnimation = .contentFrameUpdate
            configuration.backgroundInteractionBehavior = .tapToDismiss
        }
    }

    private func header(from viewState: ReceiveMainViewModel.ViewState) -> some View {
        var title: String?
        var backButtonAction: (() -> Void)?
        var closeButtonAction: (() -> Void)?

        switch viewState {
        case .tokenAlert, .yieldTokenAlert:
            title = nil
            backButtonAction = nil
            closeButtonAction = viewModel.onCloseTapAction
        case .selector:
            title = Localization.domainReceiveAssetsNavigationTitle
            backButtonAction = nil
            closeButtonAction = viewModel.onCloseTapAction
        case .qrCode:
            title = nil
            backButtonAction = viewModel.onBackTapAction
            closeButtonAction = viewModel.onCloseTapAction
        }

        return FloatingSheetNavigationBarView(
            title: title,
            backgroundColor: viewState.backgroundColor,
            backButtonAction: backButtonAction,
            closeButtonAction: closeButtonAction
        )
        .id(viewState.id)
        .transition(.opacity)
        .transformEffect(.identity)
        .animation(.headerOpacity.delay(0.2), value: viewState.id)
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

extension ReceiveMainView {
    private enum Layout {
        static let scrollViewCoordinateSpace = "ReceiveAssetsCoordinatorView.ScrollView"
    }
}
