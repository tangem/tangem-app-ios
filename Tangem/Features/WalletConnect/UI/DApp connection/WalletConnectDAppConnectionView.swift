//
//  WalletConnectDAppConnectionView.swift
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

struct WalletConnectDAppConnectionView: View {
    @ObservedObject var viewModel: WalletConnectDAppConnectionViewModel
    let kingfisherImageCache: ImageCache

    @State private var navigationBarBottomSeparatorIsVisible = false

    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView(.vertical) {
                contentStateView(scrollProxy)
                    .readGeometry(
                        \.frame.minY,
                        inCoordinateSpace: .named(Layout.scrollViewCoordinateSpace),
                        throttleInterval: .proMotion,
                        onChange: updateNavigationBarBottomSeparatorVisibility
                    )
            }
            .safeAreaInset(edge: .top, spacing: .zero) {
                header
            }
            .safeAreaInset(edge: .bottom, spacing: .zero) {
                footer
            }
            .scrollBounceBehavior(.basedOnSize)
            .coordinateSpace(name: Layout.scrollViewCoordinateSpace)
        }
        .floatingSheetConfiguration { configuration in
            configuration.sheetBackgroundColor = Colors.Background.tertiary
            configuration.sheetFrameUpdateAnimation = .contentFrameUpdate
            configuration.backgroundInteractionBehavior = .consumeTouches
        }
    }

    private func contentStateView(_ scrollProxy: ScrollViewProxy) -> some View {
        ZStack {
            switch viewModel.state {
            case .connectionRequest(let viewModel):
                WalletConnectDAppConnectionRequestView(viewModel: viewModel, kingfisherImageCache: kingfisherImageCache)
                    .animation(.contentFrameUpdate, value: viewModel.state.connectionRequestSection.isExpanded)
                    .animation(.contentFrameUpdate, value: viewModel.state.dAppVerificationWarningSection)
                    .animation(.contentFrameUpdate, value: viewModel.state.networksWarningSection)
                    .transition(.content)

            case .verifiedDomain(let viewModel):
                WalletConnectDAppDomainVerificationView(viewModel: viewModel)
                    .transition(.content)

            case .walletSelector(let viewModel):
                WalletConnectWalletSelectorView(viewModel: viewModel, scrollProxy: scrollProxy)
                    .transition(.content)

            case .connectionTarget(let viewModel):
                AccountSelectorView(viewModel: viewModel)
                    .transition(.content)

            case .networkSelector(let viewModel):
                WalletConnectNetworksSelectorView(viewModel: viewModel)
                    .transition(.content)

            case .error(let viewModel):
                WalletConnectErrorView(viewModel: viewModel)
                    .transition(.content)
            }
        }
    }

    private var header: some View {
        let title: String?
        let backgroundColor: Color
        let backButtonAction: (() -> Void)?
        let closeButtonAction: (() -> Void)?

        switch viewModel.state {
        case .connectionRequest(let viewModel):
            title = viewModel.state.navigationTitle
            backgroundColor = Colors.Background.tertiary
            backButtonAction = nil
            closeButtonAction = { viewModel.handle(viewEvent: .navigationCloseButtonTapped) }

        case .verifiedDomain(let viewModel):
            title = nil
            backgroundColor = Color.clear
            backButtonAction = nil
            closeButtonAction = { viewModel.handle(viewEvent: .navigationCloseButtonTapped) }

        case .walletSelector(let viewModel):
            title = viewModel.state.navigationTitle
            backgroundColor = Colors.Background.tertiary
            backButtonAction = { viewModel.handle(viewEvent: .navigationBackButtonTapped) }
            closeButtonAction = nil

        case .networkSelector(let viewModel):
            title = viewModel.state.navigationBarTitle
            backgroundColor = Colors.Background.tertiary
            backButtonAction = { viewModel.handle(viewEvent: .navigationBackButtonTapped) }
            closeButtonAction = nil

        case .connectionTarget(let viewModel):
            title = viewModel.state.navigationBarTitle
            backgroundColor = Colors.Background.tertiary
            backButtonAction = { self.viewModel.openConnectionRequest() }
            closeButtonAction = nil

        case .error(let viewModel):
            title = nil
            backgroundColor = Colors.Background.tertiary
            backButtonAction = nil
            closeButtonAction = { viewModel.handle(viewEvent: .closeButtonTapped) }
        }

        return FloatingSheetNavigationBarView(
            title: title,
            backgroundColor: backgroundColor,
            bottomSeparatorLineIsVisible: navigationBarBottomSeparatorIsVisible,
            backButtonAction: backButtonAction,
            closeButtonAction: closeButtonAction,
            titleAccessibilityIdentifier: WalletConnectAccessibilityIdentifiers.headerTitle
        )
        .id(viewModel.state.id)
        .transition(.opacity)
        .transformEffect(.identity)
        .animation(.headerOpacity.delay(0.2), value: viewModel.state.id)
    }

    private var footer: some View {
        ZStack {
            switch viewModel.state {
            case .connectionRequest(let viewModel):
                connectionRequestFooter(viewModel)
                    .transition(.footer)

            case .verifiedDomain(let viewModel):
                domainVerificationFooter(viewModel)
                    .transition(.footer)

            case .walletSelector, .connectionTarget:
                EmptyView()

            case .networkSelector(let viewModel):
                networksSelectorFooter(viewModel)
                    .transition(.footer)

            case .error(let viewModel):
                errorFooter(viewModel)
                    .transition(.footer)
            }
        }
        .background {
            ListFooterOverlayShadowView(
                color: Colors.Background.tertiary,
                opacities: [0.0, 0.95, 1]
            )
            .padding(.top, 6)
        }
        .animation(.contentFrameUpdate, value: viewModel.state.id)
    }

    private func connectionRequestFooter(_ viewModel: WalletConnectDAppConnectionRequestViewModel) -> some View {
        HStack(spacing: 8) {
            MainButton(
                title: viewModel.state.cancelButton.title,
                style: .secondary,
                isLoading: viewModel.state.cancelButton.isLoading,
                isDisabled: !viewModel.state.cancelButton.isEnabled,
                action: {
                    viewModel.handle(viewEvent: .cancelButtonTapped)
                }
            )
            .accessibilityIdentifier(WalletConnectAccessibilityIdentifiers.cancelButton)

            MainButton(
                title: viewModel.state.connectButton.title,
                isLoading: viewModel.state.connectButton.isLoading,
                isDisabled: !viewModel.state.connectButton.isEnabled,
                action: {
                    viewModel.handle(viewEvent: .connectButtonTapped)
                }
            )
            .accessibilityIdentifier(WalletConnectAccessibilityIdentifiers.connectButton)
        }
        .padding(16)
        .transformEffect(.identity)
    }

    private func domainVerificationFooter(_ viewModel: WalletConnectDAppDomainVerificationViewModel) -> some View {
        VStack(spacing: 8) {
            ForEach(viewModel.state.buttons, id: \.self) { buttonState in
                MainButton(
                    title: buttonState.title,
                    style: buttonState.style.toMainButtonStyle,
                    isLoading: buttonState.isLoading,
                    action: {
                        viewModel.handle(viewEvent: .actionButtonTapped(buttonState.role))
                    }
                )
            }
        }
        .padding(16)
        .transformEffect(.identity)
    }

    private func networksSelectorFooter(_ viewModel: WalletConnectNetworksSelectorViewModel) -> some View {
        MainButton(
            title: viewModel.state.doneButton.title,
            style: .primary,
            size: .default,
            isDisabled: !viewModel.state.doneButton.isEnabled,
            action: { viewModel.handle(viewEvent: .doneButtonTapped) }
        )
        .padding(16)
        .transformEffect(.identity)
    }

    private func errorFooter(_ viewModel: WalletConnectErrorViewModel) -> some View {
        MainButton(
            title: viewModel.state.button.title,
            style: viewModel.state.button.style.toMainButtonStyle,
            action: { viewModel.handle(viewEvent: .buttonTapped) }
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .transformEffect(.identity)
    }

    private func updateNavigationBarBottomSeparatorVisibility(_ scrollViewMinY: CGFloat) {
        navigationBarBottomSeparatorIsVisible = scrollViewMinY < Layout.navigationBarHeight - Layout.contentTopPadding
    }
}

private extension Animation {
    static let headerOpacity = Animation.curve(.easeOutStandard, duration: 0.2)
    static let contentFrameUpdate = Animation.curve(.easeInOutRefined, duration: 0.5)
    static let footerOpacity = Animation.curve(.easeOutEmphasized, duration: 0.3)
}

private extension AnyTransition {
    static let content = AnyTransition.asymmetric(
        insertion: .opacity.animation(.curve(.easeInOutRefined, duration: 0.3).delay(0.2)),
        removal: .opacity.animation(.curve(.easeInOutRefined, duration: 0.3))
    )

    static let footer = AnyTransition.asymmetric(
        insertion: .offset(y: 200).combined(with: .opacity.animation(.footerOpacity.delay(0.2))),
        removal: .offset(y: 200).combined(with: .opacity.animation(.footerOpacity))
    )
}

private extension WalletConnectDAppConnectionViewState {
    var id: String {
        switch self {
        case .connectionRequest:
            "connectionRequest"
        case .verifiedDomain:
            "verifiedDomain"
        case .walletSelector:
            "walletSelector"
        case .networkSelector:
            "networkSelector"
        case .connectionTarget:
            "connectionTarget"
        case .error:
            "error"
        }
    }
}

private extension WalletConnectDAppDomainVerificationViewState.Button.Style {
    var toMainButtonStyle: MainButton.Style {
        switch self {
        case .primary: .primary
        case .secondary: .secondary
        }
    }
}

private extension WalletConnectErrorViewState.Button.Style {
    var toMainButtonStyle: MainButton.Style {
        switch self {
        case .primary: .primary
        case .secondary: .secondary
        }
    }
}

extension WalletConnectDAppConnectionView {
    private enum Layout {
        /// 52
        static let navigationBarHeight = FloatingSheetNavigationBarView.height
        /// 12
        static let contentTopPadding: CGFloat = 12

        static let scrollViewCoordinateSpace = "WalletConnectDAppConnectionView.ScrollView"
    }
}
