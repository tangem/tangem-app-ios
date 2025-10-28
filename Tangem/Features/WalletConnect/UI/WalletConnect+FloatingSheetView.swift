//
//  WalletConnect+FloatingSheetView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import Kingfisher
import TangemAssets
import TangemUI
import TangemAccessibilityIdentifiers

extension FloatingSheetRegistry {
    func registerWalletConnectFloatingSheets() {
        let kingfisherImageCache: ImageCache = InjectedValues[\.walletConnectKingfisherImageCache]

        register(WalletConnectDAppConnectionViewModel.self) { viewModel in
            WalletConnectDAppConnectionView(viewModel: viewModel, kingfisherImageCache: kingfisherImageCache)
        }

        register(WalletConnectConnectedDAppDetailsViewModel.self) { viewModel in
            WalletConnectConnectedDAppDetailsView(viewModel: viewModel, kingfisherImageCache: kingfisherImageCache)
        }

        register(WCTransactionViewModel.self) { viewModel in
            WCTransactionView(viewModel: viewModel, kingfisherImageCache: kingfisherImageCache)
        }

        register(WalletConnectErrorViewModel.self) { viewModel in
            WalletConnectErrorView(viewModel: viewModel)
                .includingHeaderAndFooter()
        }
    }
}

extension WalletConnectConnectedDAppDetailsViewModel: FloatingSheetContentViewModel {}
extension WalletConnectDAppConnectionViewModel: FloatingSheetContentViewModel {}
extension WalletConnectErrorViewModel: FloatingSheetContentViewModel {}

private extension WalletConnectErrorView {
    func includingHeaderAndFooter() -> some View {
        safeAreaInset(edge: .top, spacing: .zero) {
            FloatingSheetNavigationBarView(
                backgroundColor: Colors.Background.tertiary,
                bottomSeparatorLineIsVisible: false,
                closeButtonAction: { viewModel.handle(viewEvent: .closeButtonTapped) },
                titleAccessibilityIdentifier: WalletConnectAccessibilityIdentifiers.headerTitle
            )
        }
        .safeAreaInset(edge: .bottom, spacing: .zero) {
            MainButton(
                title: viewModel.state.button.title,
                style: viewModel.state.button.style.toMainButtonStyle,
                action: { viewModel.handle(viewEvent: .buttonTapped) }
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .transformEffect(.identity)
        }
    }
}

private extension WalletConnectErrorViewState.Button.Style {
    var toMainButtonStyle: MainButton.Style {
        switch self {
        case .primary: .primary
        case .secondary: .secondary
        }
    }
}
