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
import TangemAccessibilityIdentifiers

struct MobileCreateWalletView: View {
    typealias ViewModel = MobileCreateWalletViewModel

    @ObservedObject var viewModel: ViewModel

    var body: some View {
        content
            .padding(.horizontal, 16)
            .safeAreaInset(edge: .top) { navigationBar }
            .allowsHitTesting(!viewModel.isCreating)
            .onFirstAppear(perform: viewModel.onFirstAppear)
            .alert(item: $viewModel.alert, content: { $0.alert })
    }
}

// MARK: - Subviews

private extension MobileCreateWalletView {
    var navigationBar: some View {
        NavigationBar(
            title: .empty,
            settings: .init(backgroundColor: .clear),
            leftButtons: {
                BackButton(
                    height: viewModel.navBarHeight,
                    isVisible: true,
                    isEnabled: true,
                    action: viewModel.onBackTap
                )
            }
        )
    }

    var content: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                Assets.MobileWallet.mobileWalletWithoutFrame.image
                    .renderingMode(.template)
                    .foregroundColor(Colors.Icon.secondary)

                Text(viewModel.title)
                    .style(Fonts.Bold.title1, color: Colors.Text.primary1)
                    .multilineTextAlignment(.center)
                    .padding(.top, 20)

                VStack(spacing: 28) {
                    ForEach(viewModel.infoItems) {
                        infoItem($0)
                    }
                }
                .padding(.top, 32)
            }
            .padding(.top, 64)
            .padding(.horizontal, 24)
        }
        .safeAreaInset(edge: .bottom, spacing: 16) {
            actionButtons
                .bottomPaddingIfZeroSafeArea()
        }
    }

    func infoItem(_ item: ViewModel.InfoItem) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Colors.Control.unchecked)
                    .frame(width: 42)

                item.icon.image
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(Colors.Icon.primary1)
                    .frame(width: 24, height: 24)
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
    }

    var actionButtons: some View {
        VStack(spacing: 8) {
            MainButton(
                title: viewModel.importButtonTitle,
                style: .secondary,
                action: viewModel.onImportTap
            )
            .accessibilityIdentifier(OnboardingAccessibilityIdentifiers.mobileCreateWalletImportButton)

            MainButton(
                title: viewModel.createButtonTitle,
                style: .primary,
                isLoading: viewModel.isCreating,
                action: viewModel.onCreateTap
            )
            .accessibilityIdentifier(OnboardingAccessibilityIdentifiers.mobileCreateWalletCreateButton)
        }
    }
}
