//
//  WCTransactionView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import Kingfisher
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils
import TangemAccessibilityIdentifiers

struct WCTransactionView: View {
    @ObservedObject var viewModel: WCTransactionViewModel
    let kingfisherImageCache: ImageCache

    var body: some View {
        floatingSheetContent
            .safeAreaInset(edge: .top, spacing: 12) {
                header
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                footer
            }
            .allowsHitTesting(viewModel.presentationState != .signing)
            .animation(.contentFrameUpdate, value: viewModel.presentationState)
            .floatingSheetConfiguration { configuration in
                configuration.sheetBackgroundColor = Colors.Background.tertiary
                configuration.sheetFrameUpdateAnimation = .contentFrameUpdate
                configuration.backgroundInteractionBehavior = .consumeTouches
            }
    }

    private var floatingSheetContent: some View {
        ZStack {
            switch viewModel.presentationState {
            case .signing, .transactionDetails:
                scrollableSections
                    .transition(.content)
            case .requestData(let input):
                WCRequestDetailsView(input: input)
                    .transition(.content)
            case .feeSelector(let viewModel):
                WCFeeSelectorView(viewModel: viewModel)
                    .transition(.content)
            case .customAllowance(let viewModel):
                WCCustomAllowanceView(viewModel: viewModel)
                    .transition(.content)
            case .securityAlert(let viewModel):
                WCTransactionSecurityAlertView(viewModel: viewModel)
                    .transition(.content)
            case .multipleTransactionsAlert(let viewModel):
                WCMultipleTransactionAlertView(viewModel: viewModel)
                    .transition(.content)
            case .loading:
                WCTransactionSendLoadingView()
                    .transition(.content)
            }
        }
    }

    private var header: some View {
        let title: String?
        var backButtonAction: (() -> Void)? = { viewModel.handleViewAction(.returnTransactionDetails) }
        var closeButtonAction: (() -> Void)? = nil

        switch viewModel.presentationState {
        case .signing, .transactionDetails:
            title = Localization.wcTransactionFlowTitle
            backButtonAction = nil
            closeButtonAction = { viewModel.handleViewAction(.dismissTransactionView) }
        case .requestData:
            title = Localization.wcTransactionRequestTitle
        case .feeSelector:
            title = Localization.commonNetworkFeeTitle
        case .customAllowance:
            title = Localization.wcCustomAllowanceTitle
        case .securityAlert, .multipleTransactionsAlert:
            title = nil
        case .loading:
            title = nil
            backButtonAction = nil
        }

        return FloatingSheetNavigationBarView(
            title: title,
            backgroundColor: Colors.Background.tertiary,
            backButtonAction: backButtonAction,
            closeButtonAction: closeButtonAction,
            titleAccessibilityIdentifier: WalletConnectAccessibilityIdentifiers.headerTitle
        )
        .id(viewModel.presentationState.stateId)
        .transition(.opacity)
        .transformEffect(.identity)
        .animation(.headerOpacity.delay(0.2), value: viewModel.presentationState)
    }

    private var footer: some View {
        ZStack {
            switch viewModel.presentationState {
            case .signing, .transactionDetails:
                actionButtons
                    .transformEffect(.identity)
                    .transition(.footer)
            case .requestData(let input):
                requestDetailsFooter(input)
                    .transformEffect(.identity)
                    .transition(.footer)
            case .feeSelector(let viewModel):
                feeSelectorFooter(viewModel)
                    .transformEffect(.identity)
                    .transition(.footer)
            case .customAllowance(let viewModel):
                customAllowanceFooter(viewModel)
                    .transformEffect(.identity)
                    .transition(.footer)
            case .securityAlert(let viewModel):
                securityAlertFooter(viewModel: viewModel)
                    .transformEffect(.identity)
                    .transition(.footer)
            case .multipleTransactionsAlert(let viewModel):
                multipleTransactionAlertFooter(viewModel: viewModel)
                    .transformEffect(.identity)
                    .transition(.footer)
            case .loading:
                EmptyView()
            }
        }
        .padding(16)
        .background {
            ListFooterOverlayShadowView(
                color: Colors.Background.tertiary,
                opacities: [0.0, 0.95, 1]
            )
            .padding(.top, 6)
        }
        .animation(.contentFrameUpdate, value: viewModel.presentationState.stateId)
    }

    private var actionButtons: some View {
        HStack(spacing: 8) {
            MainButton(
                settings: .init(
                    title: Localization.commonCancel,
                    style: .secondary,
                    action: { viewModel.handleViewAction(.cancel) }
                )
            )

            MainButton(
                settings: .init(
                    title: viewModel.primariActionButtonTitle,
                    icon: viewModel.tangemIconProvider.getMainButtonIcon(),
                    isLoading: viewModel.presentationState == .signing,
                    isDisabled: viewModel.isActionButtonBlocked,
                    action: { viewModel.handleViewAction(.sign) }
                )
            )
        }
    }

    private func requestDetailsFooter(_ input: WCRequestDetailsInput) -> some View {
        MainButton(
            title: Localization.wcCopyDataButtonText,
            icon: .trailing(Assets.Glyphs.copy),
            style: .primary,
            size: .default,
            action: input.copyTransactionData
        )
    }

    private func customAllowanceFooter(_ viewModel: WCCustomAllowanceViewModel) -> some View {
        MainButton(
            title: Localization.commonDone,
            isDisabled: !viewModel.canSubmit,
            action: {
                Task {
                    await viewModel.handleViewAction(.done)
                }
            }
        )
    }

    private func feeSelectorFooter(_ viewModel: WCFeeSelectorContentViewModel) -> some View {
        MainButton(title: Localization.commonDone, action: viewModel.done)
    }

    private func securityAlertFooter(viewModel: WCTransactionSecurityAlertViewModel) -> some View {
        VStack(spacing: 8) {
            makeAlertButton(
                from: viewModel.state.primaryButton,
                action: { viewModel.handleViewAction(.primaryButtonTapped) }
            )

            makeAlertButton(
                from: viewModel.state.secondaryButton,
                icon: viewModel.state.tangemIcon,
                action: { viewModel.handleViewAction(.secondaryButtonTapped) }
            )
        }
    }

    private func multipleTransactionAlertFooter(viewModel: WCMultipleTransactionAlertViewModel) -> some View {
        VStack(spacing: 8) {
            makeAlertButton(
                from: viewModel.state.secondaryButton,
                action: { viewModel.handleViewAction(.secondaryButtonTapped) }
            )

            makeAlertButton(
                from: viewModel.state.primaryButton,
                action: { viewModel.handleViewAction(.primaryButtonTapped) }
            )
        }
    }

    private func makeAlertButton(
        from state: WCTransactionAlertState.ButtonSettings,
        icon: MainButton.Icon? = nil,
        action: @escaping () -> Void
    ) -> MainButton {
        MainButton(
            settings: .init(
                title: state.title,
                icon: icon,
                style: state.style,
                isLoading: state.isLoading,
                action: action
            )
        )
    }
}

private extension WCTransactionView {
    var scrollableSections: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                dappInfoSection

                ForEach(viewModel.simulationValidationInputs) {
                    NotificationView(input: $0)
                }

                simulationResultSection

                transactionDetailsContent

                ForEach(viewModel.feeValidationInputs) {
                    NotificationView(input: $0)
                }
            }
            .padding(.horizontal, 16)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    var dappInfoSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(Localization.wcRequestFrom)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                .padding(.bottom, 14)
                .lineLimit(1)

            WCDappTitleView(
                dAppData: viewModel.transactionData.dAppData,
                isVerified: viewModel.isDappVerified,
                kingfisherImageCache: kingfisherImageCache
            )

            Separator(height: .minimal, color: Colors.Stroke.primary)
                .padding(.vertical, 12)

            transactionRequest
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(Colors.Background.action)
        .cornerRadius(14, corners: .allCorners)
    }

    var transactionRequest: some View {
        Button(action: { viewModel.handleViewAction(.showRequestData) }) {
            HStack(alignment: .center, spacing: 8) {
                Assets.Glyphs.docNew.image
                    .renderingMode(.template)
                    .foregroundStyle(Colors.Icon.accent)

                Text(Localization.wcTransactionRequest)
                    .style(Fonts.Regular.body, color: Colors.Text.primary1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Assets.Glyphs.chevronRightNew.image
                    .renderingMode(.template)
                    .foregroundStyle(Colors.Icon.informative)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    private var simulationResultSection: some View {
        WCTransactionSimulationView(displayModel: viewModel.simulationDisplayModel)
    }
}

private extension WCTransactionView {
    @ViewBuilder
    var transactionDetailsContent: some View {
        switch viewModel.transactionData.method {
        case .personalSign, .signTypedData, .signTypedDataV4:
            WCEthPersonalSignTransactionView(
                connectionTargetKind: viewModel.connectionTargetKind,
                blockchain: viewModel.transactionData.blockchain,
                addressRowViewModel: viewModel.addressRowViewModel
            )
        case .addChain:
            addChainContextRow
        case .solanaSignMessage, .solanaSignTransaction, .solanaSignAllTransactions:
            WCSolanaDefaultTransactionDetailsView(
                connectionTargetKind: viewModel.connectionTargetKind
            )
        case .sendTransaction, .signTransaction:
            WCEthTransactionDetailsView(viewModel: viewModel)
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private var addChainContextRow: some View {
        if let connectionTargetKind = viewModel.connectionTargetKind {
            WCTransactionConnectionTargetRow(kind: connectionTargetKind)
                .background(Colors.Background.action)
                .cornerRadius(14, corners: .allCorners)
        }
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

private enum Constants {
    static var scrollContentBottomPadding: CGFloat { MainButton.Size.default.height + 28 }
}
