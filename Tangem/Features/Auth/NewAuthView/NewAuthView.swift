//
//  NewAuthView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils
import TangemAccessibilityIdentifiers

struct NewAuthView: View {
    typealias ViewModel = NewAuthViewModel

    @ObservedObject var viewModel: ViewModel

    var body: some View {
        stateView
            .allowsHitTesting(!viewModel.isUnlocking)
            .alert(item: $viewModel.alert, content: { $0.alert })
            .background(Colors.Background.secondary.ignoresSafeArea())
            .onFirstAppear(perform: viewModel.onFirstAppear)
            .onAppear(perform: viewModel.onAppear)
            .onDisappear(perform: viewModel.onDisappear)
    }
}

// MARK: - States

private extension NewAuthView {
    var stateView: some View {
        ZStack {
            switch viewModel.state {
            case .locked:
                LockView(usesNamespace: false)
                    .transition(.opacity.animation(.easeIn))

            case .wallets(let item):
                walletsView(item: item)
                    .tangemLogoNavigationToolbar(trailingItem: trailingNavigationBarItem(item: item.addWalletButton))
                    .transition(.opacity.animation(.easeIn))

            case .none:
                EmptyView()
            }
        }
    }

    func walletsView(item: ViewModel.WalletsStateItem) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 32) {
                infoView(title: item.title, description: item.description)
                walletsView(items: item.wallets)
            }
            .padding(.top, 32)
            .padding(.horizontal, 16)
            .ignoresSafeArea(edges: .bottom)
        }
        .safeAreaInset(edge: .bottom, spacing: 10) {
            item.biometricsUnlockButton.map {
                biometricsUnlockButton(item: $0)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 6)
            }
        }
        .accessibilityIdentifier(AuthAccessibilityIdentifiers.walletsList)
    }
}

// MARK: - NavigationBar

private extension NewAuthView {
    func trailingNavigationBarItem(item: ViewModel.Button) -> some View {
        Button(action: item.action) {
            Text(item.title)
                .style(Fonts.Regular.body, color: Colors.Text.primary1)
        }
        .allowsHitTesting(!viewModel.isUnlocking)
        .accessibilityIdentifier(AuthAccessibilityIdentifiers.addWalletButton)
    }
}

// MARK: - WalletsState subviews

private extension NewAuthView {
    func infoView(title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .style(Fonts.Bold.title1, color: Colors.Text.primary1)
                .accessibilityIdentifier(AuthAccessibilityIdentifiers.title)

            Text(description)
                .style(Fonts.Regular.callout, color: Colors.Text.secondary)
                .accessibilityIdentifier(AuthAccessibilityIdentifiers.subtitle)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func walletsView(items: [ViewModel.WalletItem]) -> some View {
        VStack(spacing: 8) {
            ForEach(items) { walletItem in
                NewAuthWalletView(item: walletItem)
                    .confirmationDialog(
                        viewModel: walletItem.scanTroubleshootingDialog,
                        onDismiss: {
                            viewModel.onScanTroubleshootingDialogDismiss(for: walletItem.id)
                        }
                    )
                    .environment(\.unlockingUserWalletId, viewModel.unlockingUserWalletId)
            }
        }
    }

    func biometricsUnlockButton(item: ViewModel.Button) -> some View {
        Button(action: item.action) {
            Text(item.title)
                .style(Fonts.Bold.callout, color: Colors.Text.primary1)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .center)
                .background(Colors.Button.secondary)
                .cornerRadius(14, corners: .allCorners)
        }
        .colorScheme(.dark)
        .accessibilityIdentifier(AuthAccessibilityIdentifiers.biometricsUnlockButton)
    }
}
