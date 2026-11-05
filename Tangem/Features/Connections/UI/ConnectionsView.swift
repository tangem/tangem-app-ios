//
//  ConnectionsView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import Kingfisher
import TangemAssets
import TangemUI
import TangemUIUtils

struct ConnectionsView: View {
    @ObservedObject var viewModel: ConnectionsViewModel
    let imageCache: Kingfisher.ImageCache

    var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: tabIDSelection) {
                ForEach(viewModel.state.tabs.map(\.id), id: \.self) { tabID in
                    ConnectionsUserWalletTabView(viewModel: viewModel, tabID: tabID, imageCache: imageCache)
                        .safeAreaInset(edge: .top, spacing: 0) {
                            if viewModel.state.isTabBarVisible {
                                Color.clear.frame(height: 52)
                            }
                        }
                        .tag(tabID)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            if viewModel.state.isTabBarVisible {
                TabNavigation(data: viewModel.state.tabItems, selection: tabItemSelection)
                    .scrollable()
                    .hapticFeedback()
                    .padding(.top, 8)
            }
        }
        .footer {
            Footer(.buttons(primary: newConnectionButton(viewModel.state.newConnectionButton)))
                .showFade()
        }
        .confirmationDialog(for: viewModel.state.modalDialog, dismissAction: dismissDialogAction)
        .navigationTitle(viewModel.state.navigationBar.title)
        .toolbar {
            trailingNavigationBarButton
        }
        .translucentNavigationBar()
        .alert(for: viewModel.state.modalDialog, dismissAction: dismissDialogAction)
        .background(DesignSystem.Color.bgPrimary)
        .onAppear {
            viewModel.handle(action: .viewDidAppear)
        }
    }

    private var tabIDSelection: Binding<ConnectionsViewState.UserWalletTab.ID> {
        Binding(
            get: { viewModel.state.selectedTabID },
            set: { tabID in
                viewModel.handle(action: .tabSelected(tabID))
            }
        )
    }

    private var tabItemSelection: Binding<ConnectionsViewState.UserWalletTab.TabItem> {
        Binding(
            get: { viewModel.state.selectedTab.tabItem },
            set: { tabItem in
                withAnimation {
                    viewModel.handle(action: .tabSelected(tabItem.id))
                }
            }
        )
    }

    @ToolbarContentBuilder
    private var trailingNavigationBarButton: some ToolbarContent {
        if let trailingButton = viewModel.state.navigationBar.trailingButton {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    SwiftUI.Button(
                        role: .destructive,
                        action: {
                            viewModel.handle(action: .disconnectAllButtonTapped)
                        },
                        label: {
                            Text(trailingButton.disconnectAllMenuTitle)
                        }
                    )
                    .disabled(!trailingButton.isEnabled)
                } label: {
                    DesignSystem.Icons.DotsHorizontal.regular24.image
                        .foregroundStyle(DesignSystem.Color.iconPrimary)
                }
                .accessibilityLabel(trailingButton.accessibilityLabel)
            }
        }
    }

    private func newConnectionButton(_ buttonState: ConnectionsViewState.NewConnectionButton) -> TangemUI.Button {
        TangemUI.Button(
            label: buttonState.title,
            accessibilityLabel: nil,
            action: {
                viewModel.handle(action: .newConnectionButtonTapped)
            }
        )
        .loading(.spinner(if: buttonState.isLoading))
        .styleType(.primary)
    }

    private func dismissDialogAction() {
        DispatchQueue.main.async {
            viewModel.handle(action: .closeDialogButtonTapped)
        }
    }
}

// MARK: - ModalDialogs wrappers

private extension View {
    func alert(for modalDialog: ConnectionsViewState.ModalDialog?, dismissAction: @escaping () -> Void) -> some View {
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

    func confirmationDialog(for modalDialog: ConnectionsViewState.ModalDialog?, dismissAction: @escaping () -> Void) -> some View {
        confirmationDialog(viewModel: modalDialog?.asConfirmationDialog, onDismiss: dismissAction)
    }
}

private extension ConnectionsViewState.ModalDialog.Alert {
    var actions: some View {
        ForEach(buttons, id: \.self) { button in
            SwiftUI.Button(button.title, role: button.role?.toSwiftUIButtonRole, action: button.action)
        }
    }
}

private extension ConnectionsViewState.ModalDialog.AlertButtonRole {
    var toSwiftUIButtonRole: ButtonRole {
        switch self {
        case .destructive: .destructive
        case .cancel: .cancel
        }
    }
}

// MARK: - TabNavigationItem

extension ConnectionsViewState.UserWalletTab.TabItem: TabNavigationItem {
    var title: String {
        name
    }

    var start: TabNavigationItemStart? {
        thumbnail.map(TabNavigationItemStart.walletThumbnail)
    }
}
