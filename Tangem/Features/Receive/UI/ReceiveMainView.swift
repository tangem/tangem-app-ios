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
    @ObservedObject var viewModel: ReceiveMainViewModel

    var body: some View {
        ZStack {
            switch viewModel.viewState {
            case .selector(let viewModel):
                SelectorReceiveAssetsView(viewModel: viewModel)
                    .transition(.content)

            case .qrCode(let viewModel):
                qrCodeView(viewModel: viewModel)
                    .transition(.content)

            case .tokenAlert(let viewModel):
                tokenAlertView(viewModel: viewModel)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.content)

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
        .floatingSheetConfiguration { configuration in
            configuration.sheetBackgroundColor = viewModel.viewState?.backgroundColor ?? Colors.Background.tertiary
            configuration.sheetFrameUpdateAnimation = .contentFrameUpdate
            configuration.backgroundInteractionBehavior = .tapToDismiss
        }
    }

    @ViewBuilder
    private func tokenAlertView(viewModel: TokenAlertReceiveAssetsViewModel) -> some View {
        if FeatureProvider.isAvailable(.redesign) {
            RedesignedTokenAlertReceiveAssetsView(viewModel: viewModel)
        } else {
            // [REDACTED_INFO]: drop the legacy token alert view once redesign ships.
            TokenAlertReceiveAssetsView(viewModel: viewModel)
        }
    }

    @ViewBuilder
    private func qrCodeView(viewModel: QRCodeReceiveAssetsViewModel) -> some View {
        if FeatureProvider.isAvailable(.redesign) {
            RedesignedQRCodeReceiveAssetsView(viewModel: viewModel)
        } else {
            // [REDACTED_INFO]: drop the legacy QR view once redesign ships.
            QRCodeReceiveAssetsView(viewModel: viewModel)
        }
    }

    private func header(from viewState: ReceiveMainViewModel.ViewState) -> some View {
        let title: String?
        let backButtonAction: (() -> Void)?

        switch viewState {
        case .tokenAlert:
            title = nil
            backButtonAction = nil
        case .selector:
            title = Localization.domainReceiveAssetsNavigationTitle
            backButtonAction = nil
        case .qrCode:
            title = nil
            backButtonAction = viewModel.onBackTapAction
        }

        return FloatingSheetNavigationBarView(
            title: title,
            backgroundColor: viewState.backgroundColor,
            backButtonAction: backButtonAction,
            closeButtonAction: viewModel.onCloseTapAction
        )
        .id(viewState.id)
        .transition(.opacity)
        .transformEffect(.identity)
        .animation(.headerOpacity.delay(0.2), value: viewState.id)
    }
}

private extension ReceiveMainViewModel.ViewState {
    var backgroundColor: Color {
        guard FeatureProvider.isAvailable(.redesign) else {
            // [REDACTED_INFO]: drop the legacy branch once redesign ships.
            switch self {
            case .selector, .tokenAlert:
                return Colors.Background.tertiary
            case .qrCode:
                return Colors.Background.primary
            }
        }
        return DesignSystem.Color.bgSecondary
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
