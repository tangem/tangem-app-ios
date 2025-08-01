//
//  WCTransactionView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import BigInt
import TangemAssets
import TangemUI
import TangemUIUtils
import BlockchainSdk
import TangemLocalization

struct WCTransactionView: View {
    @ObservedObject var viewModel: WCTransactionViewModel

    var body: some View {
        ZStack {
            switch viewModel.presentationState {
            case .signing, .transactionDetails:
                transactionDetails
                    .transition(topEdgeTransition)
            case .requestData(let input):
                WCRequestDetailsView(input: input)
                    .transition(requestDetailsTransition)
            case .feeSelector(let viewModel):
                FeeSelectorContentView(viewModel: viewModel)
                    .transition(topEdgeTransition)
            case .customAllowance(let input):
                WCCustomAllowanceView(input: input)
                    .transition(topEdgeTransition)
            case .securityAlert(let state, let input):
                WCTransactionSecurityAlertView(state: state, input: input)
                    .transition(bottomEdgeTransition)
            }
        }
        .allowsHitTesting(viewModel.presentationState != .signing)
        .animation(.contentFrameUpdate, value: viewModel.presentationState)
        .floatingSheetConfiguration { configuration in
            configuration.sheetBackgroundColor = Colors.Background.tertiary
            configuration.sheetFrameUpdateAnimation = .contentFrameUpdate
            configuration.backgroundInteractionBehavior = .consumeTouches
        }
    }

    private var transactionDetails: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 12) {
                header

                scrollableSections
            }

            actionButtons()
        }
    }

    @ViewBuilder
    private func actionButtons() -> some View {
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
                    icon: .trailing(Assets.tangemIcon),
                    isLoading: viewModel.presentationState == .signing,
                    isDisabled: viewModel.isActionButtonBlocked,
                    action: { viewModel.handleViewAction(.sign) }
                )
            )
        }
        .padding(.init(top: 0, leading: 16, bottom: 16, trailing: 16))
        .background(
            ListFooterOverlayShadowView()
                .padding(.top, -50)
        )
    }
}

private extension WCTransactionView {
    var header: some View {
        WalletConnectNavigationBarView(
            title: Localization.wcWalletConnect,
            closeButtonAction: { viewModel.handleViewAction(.dismissTransactionView) }
        )
    }

    var scrollableSections: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                dappInfoSection

                if viewModel.simulationState != .notStarted {
                    ForEach(viewModel.simulationValidationInputs) {
                        NotificationView(input: $0)
                    }

                    simulationResultSection
                        .transition(bottomEdgeTransition)
                }

                transactionDetailsContent

                ForEach(viewModel.feeValidationInputs) {
                    NotificationView(input: $0)
                }
            }
            .padding(.init(top: 0, leading: 16, bottom: Constants.scrollContentBottomPadding, trailing: 16))
        }
        .scrollBounceBehaviorBackport(.basedOnSize)
    }

    var dappInfoSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(Localization.wcRequestFrom)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                .padding(.bottom, 14)
                .lineLimit(1)

            WCDappTitleView(
                dAppData: viewModel.transactionData.dAppData,
                iconSideLength: 36,
                isVerified: viewModel.isDappVerified
            )

            Separator(height: .minimal, color: Colors.Stroke.primary)
                .padding(.vertical, 12)

            transactionRequest
                .onTapGesture {
                    viewModel.handleViewAction(.showRequestData)
                }
        }
        .padding(.init(top: 12, leading: 16, bottom: 12, trailing: 16))
        .background(Colors.Background.action)
        .cornerRadius(14, corners: .allCorners)
    }

    var transactionRequest: some View {
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
    }

    private var simulationResultSection: some View {
        WCTransactionSimulationView(displayModel: viewModel.simulationDisplayModel)
    }
}

private extension WCTransactionView {
    @ViewBuilder
    var transactionDetailsContent: some View {
        switch viewModel.transactionData.method {
        case .personalSign:
            WCEthPersonalSignTransactionView(
                walletName: viewModel.userWalletName,
                isWalletRowVisible: viewModel.isWalletRowVisible
            )
        case .solanaSignMessage, .solanaSignTransaction, .solanaSignAllTransactions:
            WCSolanaDefaultTransactionDetailsView(
                walletName: viewModel.userWalletName,
                isWalletRowVisible: viewModel.isWalletRowVisible
            )
        case .signTypedData, .signTypedDataV4:
            WCEthPersonalSignTransactionView(
                walletName: viewModel.userWalletName,
                isWalletRowVisible: viewModel.isWalletRowVisible
            )
        case .sendTransaction, .signTransaction:
            WCEthTransactionDetailsView(viewModel: viewModel)
        default:
            EmptyView()
        }
    }
}

private extension WCTransactionView {
    func makeDefaultAnimationCurve(duration: TimeInterval) -> Animation {
        .curve(.easeOutStandard, duration: duration)
    }

    var transactionDetailsTransition: AnyTransition {
        switch viewModel.transactionData.method {
        case .personalSign, .solanaSignMessage:
            bottomEdgeTransition
        case .solanaSignTransaction, .solanaSignAllTransactions:
            topEdgeTransition
        case .signTypedData, .signTypedDataV4:
            topEdgeTransition
        default:
            bottomEdgeTransition
        }
    }

    var requestDetailsTransition: AnyTransition {
        switch viewModel.transactionData.method {
        case .personalSign, .solanaSignMessage:
            topEdgeTransition
        case .solanaSignTransaction, .solanaSignAllTransactions:
            bottomEdgeTransition
        case .signTypedData, .signTypedDataV4:
            bottomEdgeTransition
        case .sendTransaction, .signTransaction:
            bottomEdgeTransition
        default:
            topEdgeTransition
        }
    }

    var bottomEdgeTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: mainContentOpacityTransitionWithDelay),
            removal: .move(edge: .bottom).combined(with: mainContentOpacityTransition)
        )
    }

    var topEdgeTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .top).combined(with: mainContentOpacityTransitionWithDelay),
            removal: .move(edge: .top).combined(with: mainContentOpacityTransition)
        )
    }

    var mainContentOpacityTransition: AnyTransition {
        .opacity.animation(.curve(.easeInOutRefined, duration: 0.3))
    }

    var mainContentOpacityTransitionWithDelay: AnyTransition {
        .opacity.animation(.curve(.easeInOutRefined, duration: 0.3).delay(0.2))
    }
}

private enum Constants {
    static var scrollContentBottomPadding: CGFloat { MainButton.Size.default.height + 28 }
}

private extension Animation {
    static let contentFrameUpdate = Animation.curve(.easeInOutRefined, duration: 0.5)
}
