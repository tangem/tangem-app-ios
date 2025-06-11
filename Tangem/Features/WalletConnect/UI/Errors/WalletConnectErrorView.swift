//
//  WalletConnectErrorView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct WalletConnectErrorView: View {
    let viewModel: WalletConnectErrorViewModel

    var body: some View {
        VStack(spacing: 24) {
            icon

            VStack(spacing: 8) {
                Text(viewModel.state.title)
                    .style(Fonts.Bold.title3.weight(.semibold), color: Colors.Text.primary1)
                    .lineLimit(2)

                Text(LocalizedStringKey(viewModel.state.subtitle))
                    .style(Fonts.Regular.subheadline, color: Colors.Text.secondary)
                    .lineLimit(6)
            }
            .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
        .padding(.horizontal, 32)
        .padding(.bottom, 44)
        .background(Colors.Background.tertiary)
        .frame(maxWidth: .infinity)
        .environment(\.openURL, OpenURLAction { _ in
            viewModel.handle(viewEvent: .contactSupportLinkTapped)
            return .handled
        })
    }

    private var icon: some View {
        viewModel.state.icon.asset.image
            .resizable()
            .frame(width: 32, height: 32)
            .foregroundStyle(viewModel.state.icon.color)
            .frame(width: 56, height: 56)
            .background {
                Circle()
                    .fill(viewModel.state.icon.color.opacity(0.1))
            }
    }
}
