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
    @ObservedObject var viewModel: NewAuthViewModel

    var body: some View {
        stateView
            .allowsHitTesting(viewModel.allowsHitTesting)
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

            case .wallets(let walletsState):
                walletsView(walletsState)
                    .tangemLogoNavigationToolbar(trailingItem: addWalletNavigationBarButton(walletsState))
                    .transition(.opacity.animation(.easeIn))

            case .none:
                EmptyView()
            }
        }
    }

    func walletsView(_ state: NewAuthViewState.WalletsState) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 32) {
                infoView(title: state.title, description: state.description)

                VStack(spacing: 8) {
                    ForEach(state.wallets) { wallet in
                        NewAuthWalletView(item: wallet)
                            .confirmationDialog(
                                viewModel: confirmationDialogViewModel(for: wallet, dialog: state.scanTroubleshootingDialog),
                                onDismiss: viewModel.onScanTroubleshootingDialogDismiss
                            )
                            .environment(\.unlockingUserWalletId, viewModel.unlockingUserWalletId)
                    }
                }
            }
            .padding(.top, 32)
            .padding(.horizontal, 16)
            .ignoresSafeArea(edges: .bottom)
        }
        .safeAreaInset(edge: .bottom, spacing: 10) {
            state.biometricsUnlockButton.map {
                biometricsUnlockButton(item: $0)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 6)
            }
        }
        .accessibilityIdentifier(AuthAccessibilityIdentifiers.walletsList)
    }

    func confirmationDialogViewModel(
        for walletItem: NewAuthViewState.WalletItem,
        dialog: NewAuthViewState.ScanTroubleshootingDialog?
    ) -> ConfirmationDialogViewModel? {
        guard let dialog, case .wallet(let userWalletID) = dialog.placement else { return nil }

        return walletItem.id == userWalletID
            ? dialog.viewModel
            : nil
    }

    func confirmationDialogViewModelForAddButton(_ state: NewAuthViewState.WalletsState) -> ConfirmationDialogViewModel? {
        guard let dialog = state.scanTroubleshootingDialog, case .addWalletButton = dialog.placement else { return nil }

        return dialog.viewModel
    }
}

// MARK: - NavigationBar

private extension NewAuthView {
    func addWalletNavigationBarButton(_ state: NewAuthViewState.WalletsState) -> some View {
        Button(action: state.addWalletButton.action) {
            Text(state.addWalletButton.title)
                .style(Fonts.Regular.body, color: Colors.Text.primary1)
        }
        .allowsHitTesting(viewModel.allowsHitTesting)
        .confirmationDialog(viewModel: confirmationDialogViewModelForAddButton(state), onDismiss: viewModel.onScanTroubleshootingDialogDismiss)
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

    func biometricsUnlockButton(item: NewAuthViewState.Button) -> some View {
        Button(action: item.action) {
            HStack(spacing: 6) {
                Text(item.title)
                    .style(Fonts.Bold.callout, color: Colors.Text.primary1)

                BiometryLogoImage.image
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                    .foregroundStyle(Colors.Text.primary1)
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .center)
            .background(Colors.Button.secondary)
            .cornerRadius(14, corners: .allCorners)
        }
        .colorScheme(.dark)
        .accessibilityIdentifier(AuthAccessibilityIdentifiers.biometricsUnlockButton)
    }
}
