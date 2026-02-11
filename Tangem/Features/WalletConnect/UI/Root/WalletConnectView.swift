//
//  WalletConnectView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import Kingfisher
import TangemAssets
import TangemUI
import TangemUIUtils
import TangemAccessibilityIdentifiers
import TangemAccounts

struct WalletConnectView: View {
    @ObservedObject var viewModel: WalletConnectViewModel
    let kingfisherImageCache: ImageCache

    @Namespace private var newConnectionButtonNamespace

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                stateView(proxy)
                    .padding(.horizontal, 16)
            }
        }
        .safeAreaInset(edge: .bottom, alignment: .center, spacing: .zero) {
            if viewModel.state.contentState.isContent {
                newConnectionButton
                    .background {
                        ListFooterOverlayShadowView(color: Colors.Background.secondary)
                            .transition(.opacity)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, UIDevice.current.hasHomeScreenIndicator ? .zero : 8)
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .animation(.easeInOut(duration: 0.2), value: viewModel.state)
        .navigationTitle(viewModel.state.navigationBar.title)
        .toolbar {
            navigationButton
        }
        .alert(for: viewModel.state.dialog, dismissAction: dismissDialogAction)
        .background(Colors.Background.secondary)
        .onAppear {
            viewModel.handle(viewEvent: .viewDidAppear)
        }
    }

    private var navigationButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if viewModel.state.contentState.isContent {
                Menu {
                    Button(
                        role: .destructive,
                        action: { viewModel.handle(viewEvent: .disconnectAllDAppsButtonTapped) },
                        label: {
                            Text(viewModel.state.navigationBar.disconnectAllMenuTitle)
                        }
                    )
                } label: {
                    viewModel.state.navigationBar.trailingButtonAsset
                        .image
                        .foregroundStyle(Colors.Icon.primary1)
                }
            }
        }
    }

    @ViewBuilder
    private func stateView(_ geometryProxy: GeometryProxy) -> some View {
        switch viewModel.state.contentState {
        case .empty(let emptyContentState):
            emptyStateView(emptyContentState)
                .frame(height: geometryProxy.size.height - geometryProxy.safeAreaInsets.top)
                .transition(.opacity)

        case .loading(let loadingContentState):
            loadingStateView(loadingContentState)
                .transition(.opacity)

        case .content(let walletsWithConnectedDApps):
            contentStateView(walletsWithConnectedDApps)
                .transition(.opacity)
        }
    }

    private func emptyStateView(_ emptyContentState: WalletConnectViewState.ContentState.EmptyContentState) -> some View {
        VStack(spacing: .zero) {
            emptyContentState.asset.image
                .resizable()
                .scaledToFit()
                .frame(width: 76, height: 76)

            Spacer()
                .frame(height: 24)

            VStack(spacing: 8) {
                Text(emptyContentState.title)
                    .style(Fonts.Regular.title3.weight(.semibold), color: Colors.Text.primary1)
                    .accessibilityIdentifier(WalletConnectAccessibilityIdentifiers.noSessionsTitle)

                Text(emptyContentState.subtitle)
                    .style(Fonts.Regular.callout, color: Colors.Text.secondary)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier(WalletConnectAccessibilityIdentifiers.noSessionsDescription)
            }

            newConnectionButton
                .padding(.top, 56)
                .padding(.horizontal, 46)
        }
    }

    private func loadingStateView(_ loadingContentState: WalletConnectViewState.ContentState.LoadingContentState) -> some View {
        VStack(alignment: .leading, spacing: .zero) {
            SkeletonView()
                .frame(width: 90, height: 18)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .padding(.horizontal, 14)

            ForEach(0 ..< loadingContentState.dAppStubsCount, id: \.self) { _ in
                dAppLoadingStubRowView
            }
        }
        .padding(.top, 12)
        .background(Colors.Background.primary)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.vertical, 12)
    }

    private var dAppLoadingStubRowView: some View {
        HStack(alignment: .bottom, spacing: 12) {
            SkeletonView()
                .frame(width: 36, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 6) {
                SkeletonView()
                    .frame(width: 74, height: 12)
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                SkeletonView()
                    .frame(width: 100, height: 12)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .padding(.bottom, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .contentShape(Rectangle())
    }

    private func contentStateView(_ walletsWithConnectedDApps: [WalletConnectViewState.ContentState.WalletWithConnectedDApps]) -> some View {
        LazyVStack(spacing: viewModel.state.usesAccountBasedLayout ? 22 : 14) {
            ForEach(walletsWithConnectedDApps, content: walletWithDAppsRowView)
        }
        .padding(.vertical, 12)
    }

    private func walletWithDAppsRowView(_ wallet: WalletConnectViewState.ContentState.WalletWithConnectedDApps) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if viewModel.state.usesAccountBasedLayout {
                if shouldShowWalletName(for: wallet) {
                    Text(wallet.walletName)
                        .style(Fonts.Bold.headline, color: Colors.Text.primary1)
                        .padding(.horizontal, 14)
                }

                if wallet.hasAccountSections {
                    VStack(spacing: 8) {
                        ForEach(wallet.accountSections, content: accountSectionView)
                    }
                } else if wallet.hasWalletLevelDApps {
                    VStack(alignment: .leading, spacing: .zero) {
                        Text(wallet.walletName)
                            .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                            .padding(.bottom, 8)
                            .padding(.horizontal, 14)

                        ForEach(wallet.walletLevelDApps, content: dAppRowView)
                    }
                    .padding(.top, 12)
                    .background(Colors.Background.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            } else {
                if wallet.hasWalletLevelDApps {
                    VStack(alignment: .leading, spacing: .zero) {
                        if shouldShowWalletName(for: wallet) {
                            Text(wallet.walletName)
                                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                                .padding(.bottom, 8)
                                .padding(.horizontal, 14)
                        }

                        ForEach(wallet.walletLevelDApps, content: dAppRowView)
                    }
                    .padding(.top, 12)
                    .background(Colors.Background.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
        .animation(.bouncy(duration: 0.2), value: wallet)
    }

    private func accountSectionView(_ section: WalletConnectViewState.ContentState.AccountSection) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            accountSectionHeader(section)
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .padding(.bottom, 6)

            ForEach(section.dApps, content: dAppRowView)
        }
        .background(Colors.Background.action)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func accountSectionHeader(_ section: WalletConnectViewState.ContentState.AccountSection) -> some View {
        HStack(spacing: 12) {
            AccountIconView(
                data: AccountModelUtils.UI.iconViewData(icon: section.icon, accountName: section.name),
                settings: .defaultSized
            )
            .settings(.smallSized)

            Text(section.name)
                .style(Fonts.Regular.caption1, color: Colors.Text.primary1)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func shouldShowWalletName(for wallet: WalletConnectViewState.ContentState.WalletWithConnectedDApps) -> Bool {
        return viewModel.state.shouldDisplayWalletNames && wallet.hasAccountSections
    }

    private func dAppRowView(_ dApp: WalletConnectViewState.ContentState.ConnectedDApp) -> some View {
        Button(action: { viewModel.handle(viewEvent: .dAppTapped(dApp.domainModel)) }) {
            HStack(spacing: 12) {
                iconView(dApp)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .top, spacing: 6) {
                        Text(dApp.name)
                            .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                        if let verifiedDomainIconAsset = dApp.verifiedDomainIconAsset {
                            verifiedDomainIconAsset
                                .image
                                .resizable()
                                .frame(width: 16, height: 16)
                                .foregroundStyle(Colors.Icon.accent)
                                .padding(.top, 2)
                        }
                    }

                    Text(dApp.domain)
                        .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(WalletConnectAccessibilityIdentifiers.dAppRow)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func iconView(_ dApp: WalletConnectViewState.ContentState.ConnectedDApp) -> some View {
        ZStack {
            switch dApp.iconURL {
            case .some(let iconURL):
                remoteIcon(iconURL)
                    .transition(.opacity)

            case .none:
                fallbackIconAsset
                    .transition(.opacity)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var fallbackIconAsset: some View {
        Assets.Glyphs.explore.image
            .resizable()
            .scaledToFit()
            .frame(width: 20, height: 20)
            .foregroundStyle(Colors.Icon.accent)
            .frame(width: 36, height: 36)
            .background(Colors.Icon.accent.opacity(0.1))
    }

    private func remoteIcon(_ iconURL: URL) -> some View {
        KFImage(iconURL)
            .targetCache(kingfisherImageCache)
            .cancelOnDisappear(true)
            .resizable(capInsets: .init(), resizingMode: .stretch)
            .scaledToFill()
            .frame(width: 36, height: 36)
    }

    private var newConnectionButton: some View {
        MainButton(
            title: viewModel.state.newConnectionButton.title,
            isLoading: viewModel.state.newConnectionButton.isLoading,
            action: {
                viewModel.handle(viewEvent: .newConnectionButtonTapped)
            }
        )
        .matchedGeometryEffect(id: viewModel.state.newConnectionButton.title, in: newConnectionButtonNamespace)
        .accessibilityIdentifier(WalletConnectAccessibilityIdentifiers.newConnectionButton)
        .confirmationDialog(for: viewModel.state.dialog, dismissAction: dismissDialogAction)
    }

    private func dismissDialogAction() {
        viewModel.handle(viewEvent: .closeDialogButtonTapped)
    }
}

// MARK: - ModalDialogs wrappers

private extension View {
    func alert(for modalDialog: WalletConnectViewState.ModalDialog?, dismissAction: @escaping () -> Void) -> some View {
        alert(
            modalDialog?.asAlert?.title ?? "",
            isPresented: Binding(
                get: { modalDialog?.asAlert != nil },
                set: { isPresented in
                    if !isPresented {
                        dismissAction()
                    }
                }
            ),
            presenting: modalDialog?.asAlert,
            actions: { alert in
                alert.actions
            },
            message: { alert in
                Text(alert.subtitle)
            }
        )
    }

    func confirmationDialog(for modalDialog: WalletConnectViewState.ModalDialog?, dismissAction: @escaping () -> Void) -> some View {
        confirmationDialog(viewModel: modalDialog?.asConfirmationDialog, onDismiss: dismissAction)
    }
}

private extension WalletConnectViewState.ModalDialog.Alert {
    var actions: some View {
        ForEach(buttons, id: \.self) { button in
            Button(button.title, role: button.role?.toSwiftUIButtonRole, action: button.action)
        }
    }
}

private extension WalletConnectViewState.ModalDialog.AlertButtonRole {
    var toSwiftUIButtonRole: ButtonRole {
        switch self {
        case .destructive: .destructive
        case .cancel: .cancel
        }
    }
}
