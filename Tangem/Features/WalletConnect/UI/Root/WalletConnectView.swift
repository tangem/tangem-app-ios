//
//  WalletConnectView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct WalletConnectView: View {
    @ObservedObject var viewModel: WalletConnectViewModel

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: viewModel.state.contentState.zStackAlignment) {
                ScrollView(viewModel.state.contentState.scrollViewAxis) {
                    stateView(proxy)
                        .frame(
                            minHeight: proxy.size.height,
                            alignment: viewModel.state.contentState.stateViewAlignment
                        )
                        .padding(.horizontal, 16)
                }

                newConnectionButton
            }
            .scrollDisabledBackport(viewModel.state.contentState.isEmpty)
        }
        .navigationTitle(viewModel.state.navigationBar.title)
        .toolbar {
            navigationButton
        }
        .alert(for: viewModel.state.dialog, dismissAction: dismissDialogAction)
        .confirmationDialog(for: viewModel.state.dialog, dismissAction: dismissDialogAction)
        .background(Colors.Background.secondary)
        .animation(.easeOut(duration: 0.2), value: viewModel.state)
        .onAppear {
            viewModel.handle(viewEvent: .viewDidAppear)
        }
    }

    private var navigationButton: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            if !viewModel.state.contentState.isEmpty {
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
    private func stateView(_ proxy: GeometryProxy) -> some View {
        switch viewModel.state.contentState {
        case .empty(let emptyContentState):
            emptyStateView(emptyContentState)
                .padding(.top, -proxy.safeAreaInsets.top)
                .transition(.move(edge: .top).combined(with: .opacity))

        case .withConnectedDApps(let walletsWithConnectedDApps):
            dAppListView(walletsWithConnectedDApps)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private var newConnectionButton: some View {
        MainButton(
            title: viewModel.state.newConnectionButton.title,
            isLoading: viewModel.state.newConnectionButton.isLoading,
            action: {
                viewModel.handle(viewEvent: .newConnectionButtonTapped)
            }
        )
        .padding(.top, viewModel.state.contentState.isEmpty ? 210 : .zero)
        .padding(.horizontal, viewModel.state.contentState.isEmpty ? 62 : .zero)
        .padding(.horizontal, 16)
        .padding(.bottom, UIDevice.current.hasHomeScreenIndicator ? .zero : 6)
        .background {
            if !viewModel.state.contentState.isEmpty {
                ListFooterOverlayShadowView()
                    .transition(.opacity)
            }
        }
    }

    private func emptyStateView(_ emptyContentState: WalletConnectViewState.ContentState.EmptyContentState) -> some View {
        VStack(spacing: 24) {
            emptyContentState.asset.image
                .resizable()
                .scaledToFit()
                .frame(width: 76, height: 76)

            VStack(spacing: 8) {
                Text(emptyContentState.title)
                    .style(Fonts.Regular.title3.weight(.semibold), color: Colors.Text.primary1)

                Text(emptyContentState.subtitle)
                    .style(Fonts.Regular.callout, color: Colors.Text.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func dAppListView(_ walletsWithConnectedDApps: [WalletConnectViewState.ContentState.WalletWithConnectedDApps]) -> some View {
        LazyVStack(spacing: 14) {
            ForEach(walletsWithConnectedDApps, content: walletWithDAppsRowView)
        }
        .padding(.vertical, 12)
        .padding(.bottom, 44)
        .padding(.bottom, UIDevice.current.hasHomeScreenIndicator ? .zero : 6)
    }

    private func walletWithDAppsRowView(_ wallet: WalletConnectViewState.ContentState.WalletWithConnectedDApps) -> some View {
        LazyVStack(alignment: .leading, spacing: .zero) {
            Text(wallet.walletName)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                .padding(.bottom, 8)
                .padding(.horizontal, 14)

            ForEach(wallet.dApps, content: dAppRowView)
        }
        .padding(.top, 12)
        .background(Colors.Background.primary)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .animation(.bouncy(duration: 0.2), value: wallet.dApps)
    }

    private func dAppRowView(_ dApp: WalletConnectSavedSession) -> some View {
        return Button(action: { viewModel.handle(viewEvent: .dAppTapped(dApp)) }) {
            HStack(spacing: 12) {
                // [REDACTED_TODO_COMMENT]
                RoundedRectangle(cornerRadius: 8)
                    .fill(Colors.Icon.accent.opacity(0.1))
                    .frame(width: 36, height: 36)
                    .overlay {
                        Assets.Glyphs.explore.image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundStyle(Colors.Icon.accent)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(dApp.sessionInfo.dAppInfo.name)
                            .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                        // [REDACTED_TODO_COMMENT]
                        Assets.Glyphs.verified
                            .image
                            .resizable()
                            .frame(width: 16, height: 16)
                            .foregroundStyle(Colors.Icon.accent)
                    }

                    // [REDACTED_TODO_COMMENT]
                    Text("Connected App")
                        .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func dismissDialogAction() {
        viewModel.handle(viewEvent: .closeDialogButtonTapped)
    }
}

// MARK: - ModalDialogs wrappers

private extension View {
    func alert(for modalDialog: WalletConnectViewState.ModalDialog?, dismissAction: @escaping () -> Void) -> some View {
        alert(
            modalDialog?.title ?? "",
            isPresented: Binding(
                get: { modalDialog?.isAlert == true },
                set: { isPresented in
                    if !isPresented {
                        dismissAction()
                    }
                }
            ),
            presenting: modalDialog,
            actions: { _ in
                modalDialog?.actions
            },
            message: { _ in
                Text(modalDialog?.subtitle ?? "")
            }
        )
    }

    func confirmationDialog(for modalDialog: WalletConnectViewState.ModalDialog?, dismissAction: @escaping () -> Void) -> some View {
        confirmationDialog(
            modalDialog?.title ?? "",
            isPresented: Binding(
                get: { modalDialog?.isConfirmationDialog == true },
                set: { isPresented in
                    if !isPresented {
                        dismissAction()
                    }
                }
            ),
            titleVisibility: .visible,
            presenting: modalDialog,
            actions: { _ in
                modalDialog?.actions
            },
            message: { _ in
                Text(modalDialog?.subtitle ?? "")
            }
        )
    }
}

// MARK: - ViewState utilities

private extension WalletConnectViewState.ContentState {
    var isEmpty: Bool {
        switch self {
        case .empty: true
        case .withConnectedDApps: false
        }
    }

    var scrollViewAxis: Axis.Set {
        isEmpty ? [] : .vertical
    }

    var zStackAlignment: Alignment {
        isEmpty ? .center : .bottom
    }

    var stateViewAlignment: Alignment {
        isEmpty ? .center : .top
    }
}

private extension WalletConnectViewState.ModalDialog {
    var actions: some View {
        switch self {
        case .alert(let content), .confirmationDialog(let content):
            ForEach(content.buttons, id: \.self) { button in
                Button(button.title, role: button.role?.toSwiftUIButtonRole, action: button.action)
            }
        }
    }
}

private extension WalletConnectViewState.ModalDialog.DialogButtonRole {
    var toSwiftUIButtonRole: ButtonRole {
        switch self {
        case .destructive: .destructive
        case .cancel: .cancel
        }
    }
}
