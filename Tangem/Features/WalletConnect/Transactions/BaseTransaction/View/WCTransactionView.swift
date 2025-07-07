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
            case .securityAlert(let viewModel):
                WCTransactionSecurityAlertView(viewModel: viewModel)
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
                    title: "Cancel",
                    style: .secondary,
                    action: { viewModel.handleViewAction(.cancel) }
                )
            )

            MainButton(
                settings: .init(
                    title: viewModel.primariActionButtonTitle,
                    icon: .trailing(Assets.tangemIcon),
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

// MARK: - Transaction default section

private extension WCTransactionView {
    var header: some View {
        WalletConnectNavigationBarView(
            title: "Wallet Connect",
            closeButtonAction: { viewModel.handleViewAction(.dismissTransactionView) }
        )
    }

    var scrollableSections: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                dappInfoSection

                if viewModel.simulationState != .notStarted {
                    simulationResultSection
                        .transition(bottomEdgeTransition)
                }

                transactionDetailsContent
            }
            .padding(.init(top: 0, leading: 16, bottom: Constants.scrollContentBottomPadding, trailing: 16))
        }
        .scrollBounceBehaviorBackport(.basedOnSize)
    }

    var dappInfoSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Request from")
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                .padding(.bottom, 14)

            WCDappTitleView(isLoading: false, dAppData: viewModel.dappData, iconSideLength: 36)

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

            Text("Transactions request")
                .style(Fonts.Regular.body, color: Colors.Text.primary1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Assets.Glyphs.chevronRightNew.image
                .renderingMode(.template)
                .foregroundStyle(Colors.Icon.informative)
        }
    }

    private var simulationResultSection: some View {
        WCTransactionSimulationView(displayModel: viewModel.simulationDisplayModel)
            .padding(.vertical, 4)
    }
}

// MARK: - Transactions request

private extension WCTransactionView {
    @ViewBuilder
    var transactionDetailsContent: some View {
        switch viewModel.transactionData.method {
        case .personalSign:
            WCEthPersonalSignTransactionView(walletName: viewModel.userWalletName)
        case .solanaSignMessage, .solanaSignTransaction, .solanaSignAllTransactions:
            WCSolanaDefaultTransactionDetailsView(walletName: viewModel.userWalletName)
        case .signTypedData, .signTypedDataV4:
            WCEthPersonalSignTransactionView(walletName: viewModel.userWalletName)
        case .sendTransaction, .signTransaction:
            WCEthTransactionDetailsView(viewModel: viewModel)
        default:
            EmptyView()
        }
    }
}

// MARK: - UI Helpers

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

// MARK: - Constants

private enum Constants {
    static var scrollContentBottomPadding: CGFloat { MainButton.Size.default.height + 40 } // summ padding between scroll content and overlay buttons
}

private extension Animation {
    static let contentFrameUpdate = Animation.curve(.easeInOutRefined, duration: 0.5)
}
