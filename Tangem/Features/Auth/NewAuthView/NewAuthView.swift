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
            .confirmationDialog(viewModel: $viewModel.confirmationDialog)
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
                    .toolbar { navigationBarContent(item: item.addWallet) }
                    .transition(.opacity.animation(.easeIn))
            case .none:
                EmptyView()
            }
        }
    }

    func walletsView(item: ViewModel.WalletsStateItem) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 32) {
                infoView(item: item.info)
                walletsView(items: item.wallets)
            }
            .padding(.top, 32)
            .padding(.horizontal, 16)
            .ignoresSafeArea(edges: .bottom)
        }
        .safeAreaInset(edge: .bottom, spacing: 10) {
            item.biometricsUnlock.map {
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
    @ToolbarContentBuilder
    func navigationBarContent(item: ViewModel.AddWalletItem) -> some ToolbarContent {
        ToolbarItem(
            placement: .navigationBarLeading,
            content: leadingNavigationBarItem
        )
        ToolbarItem(
            placement: .navigationBarTrailing,
            content: { trailingNavigationBarItem(item: item) }
        )
    }

    func leadingNavigationBarItem() -> some View {
        Assets.newTangemLogo.image
            .resizable()
            .renderingMode(.template)
            .aspectRatio(contentMode: .fit)
            .foregroundColor(Colors.Icon.primary1)
            .frame(width: 86, height: 18)
    }

    func trailingNavigationBarItem(item: ViewModel.AddWalletItem) -> some View {
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
    func infoView(item: ViewModel.InfoItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(item.title)
                .style(Fonts.Bold.title1, color: Colors.Text.primary1)
                .accessibilityIdentifier(AuthAccessibilityIdentifiers.title)

            Text(item.description)
                .style(Fonts.Regular.callout, color: Colors.Text.secondary)
                .accessibilityIdentifier(AuthAccessibilityIdentifiers.subtitle)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func walletsView(items: [ViewModel.WalletItem]) -> some View {
        VStack(spacing: 8) {
            ForEach(items) {
                NewAuthWalletView(item: $0)
                    .environment(\.unlockingUserWalletId, viewModel.unlockingUserWalletId)
            }
        }
    }

    func biometricsUnlockButton(item: ViewModel.BiometricsUnlockItem) -> some View {
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
