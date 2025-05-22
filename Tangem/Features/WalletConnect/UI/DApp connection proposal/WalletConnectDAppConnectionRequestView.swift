//
//  WalletConnectDAppConnectionRequestView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct WalletConnectDAppConnectionRequestView: View {
    @ObservedObject var viewModel: WalletConnectDAppConnectionRequestViewModel

    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 14) {
                Rectangle()
                    .frame(height: 400)
            }
            .padding(.horizontal, 16)
        }
        .safeAreaInset(edge: .top, spacing: .zero) {
            navigationBar
        }
        .safeAreaInset(edge: .bottom, spacing: .zero) {
            buttons
        }
        .scrollBounceBehaviorBackport(.basedOnSize)
        .frame(maxWidth: .infinity)
    }

    private var navigationBar: some View {
        WalletConnectNavigationBarView(
            title: viewModel.state.navigationTitle,
            closeButtonAction: { viewModel.handle(viewEvent: .navigationCloseButtonTapped) }
        )
    }

    private var buttons: some View {
        HStack(spacing: 8) {
            MainButton(
                title: viewModel.state.cancelButtonTitle,
                style: .secondary,
                action: {
                    viewModel.handle(viewEvent: .cancelButtonTapped)
                }
            )

            MainButton(
                title: viewModel.state.connectButtonTitle,
                action: {
                    viewModel.handle(viewEvent: .connectButtonTapped)
                }
            )
        }
        .padding(.bottom, 12)
    }
}
