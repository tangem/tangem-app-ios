//
//  MobileCreateWalletView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct MobileCreateWalletView: View {
    typealias ViewModel = MobileCreateWalletViewModel

    @ObservedObject var viewModel: ViewModel

    var body: some View {
        content
            .padding(.horizontal, 16)
            .overlay(creatingOverlay)
            .onAppear(perform: viewModel.onAppear)
    }
}

// MARK: - Subviews

private extension MobileCreateWalletView {
    var content: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                Assets.MobileWallet.mobileWallet.image

                Text(viewModel.title)
                    .style(Fonts.Bold.title1, color: Colors.Text.primary1)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                VStack(spacing: 28) {
                    ForEach(viewModel.infoItems) {
                        infoItem($0)
                    }
                }
                .padding(.top, 32)
            }
            .padding(.top, 64)
        }
        .safeAreaInset(edge: .bottom, spacing: 16) {
            actionButtons
        }
    }

    func infoItem(_ item: ViewModel.InfoItem) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Colors.Control.unchecked)
                    .frame(width: 42)

                item.icon.image
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .style(Fonts.Bold.callout, color: Colors.Icon.primary1)

                Text(item.subtitle)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 32)
    }

    var actionButtons: some View {
        VStack(spacing: 8) {
            MainButton(
                title: viewModel.createButtonTitle,
                style: .secondary,
                action: viewModel.onCreateTap
            )

            MainButton(
                title: viewModel.importButtonTitle,
                style: .primary,
                action: viewModel.onImportTap
            )
        }
    }

    @ViewBuilder
    var creatingOverlay: some View {
        if viewModel.isCreating {
            ZStack {
                Colors.Overlays.overlayPrimary
                    .ignoresSafeArea()
                ActivityIndicatorView()
            }
        }
    }
}
