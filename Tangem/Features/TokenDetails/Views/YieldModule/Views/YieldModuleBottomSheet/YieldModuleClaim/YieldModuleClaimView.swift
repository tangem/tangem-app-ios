//
//  YieldModuleClaimView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils
import TangemAssets
import TangemLocalization
import TangemAccessibilityIdentifiers

struct YieldModuleClaimView: View {
    @ObservedObject var viewModel: YieldModuleClaimViewModel

    // MARK: - View Body

    var body: some View {
        contentView
            .animation(.contentFrameUpdate, value: viewModel.viewState)
            .floatingSheetConfiguration { configuration in
                configuration.maxHeightFraction = Constants.maxHeightFraction
                configuration.sheetBackgroundColor = DesignSystem.Color.bgSecondary
                configuration.sheetFrameUpdateAnimation = .contentFrameUpdate
                configuration.backgroundInteractionBehavior = viewModel.isProcessingRequest ? .consumeTouches : .tapToDismiss
                configuration.verticalSwipeBehavior = isSwipeDismissable
                    ? .init(target: .sheet, threshold: Constants.swipeDismissThreshold)
                    : nil
            }
            .accessibilityAction(.escape) {
                guard !viewModel.isProcessingRequest else { return }

                viewModel.onCloseTap()
            }
    }

    private var isSwipeDismissable: Bool {
        !viewModel.isProcessingRequest && !viewModel.viewState.isSuccess
    }

    // MARK: - Sub Views

    @ViewBuilder
    private var contentView: some View {
        switch viewModel.viewState {
        case .claim(let viewData):
            claimContent(viewData: viewData)
                .transition(.content)

        case .success(let successData):
            YieldModuleClaimSuccessView(
                data: successData,
                networkFeeState: viewModel.networkFeeState,
                serviceFeeState: viewModel.serviceFeeState,
                feeCurrencySymbol: viewModel.feeCurrencySymbol,
                toTokenAction: viewModel.onToTokenTap,
                toYieldAction: viewModel.onCloseTap
            )
            .frame(minHeight: Self.fullSheetHeight)
            .transition(.content)
        }
    }

    private static var fullSheetHeight: CGFloat {
        (UIApplication.mainWindow?.bounds.height ?? .zero) * Constants.maxHeightFraction
    }

    private var closeButton: some View {
        TangemUI.Button(
            icon: DesignSystem.Icons.Cross.regular20,
            accessibilityLabel: Localization.commonClose,
            action: viewModel.onCloseTap
        )
        .size(.x11)
        .styleType(.material(.glass))
        .disabled(viewModel.isProcessingRequest)
    }

    private func claimContent(viewData: YieldModuleClaimViewData) -> some View {
        VStack(spacing: .zero) {
            headerView

            ScrollView(showsIndicators: false) {
                scrollContent(viewData: viewData)
                    .padding(.horizontal, Constants.horizontalPadding)
            }
            .scrollBounceBehavior(.basedOnSize)
            .safeAreaInset(edge: .bottom, spacing: .zero) {
                buttonBlock(viewData: viewData)
            }
        }
    }

    private func scrollContent(viewData: YieldModuleClaimViewData) -> some View {
        VStack(spacing: .zero) {
            totalView(viewData: viewData)
                .padding(.top, Constants.totalTopPadding)
                .padding(.bottom, Constants.totalBottomPadding)

            rewardsAndFees(viewData: viewData)
        }
    }

    private var headerView: some View {
        ZStack {
            VStack(spacing: Constants.headerSpacing) {
                Text(Localization.yieldModuleClaimSheetTitle)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

                Text(Localization.yieldModuleClaimSheetSubtitle)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, Constants.headerTextHorizontalInset)

            HStack(spacing: .zero) {
                Spacer(minLength: .zero)

                closeButton
            }
        }
        .frame(minHeight: Constants.headerHeight)
        .padding(.top, Constants.headerTopPadding)
        .padding(.bottom, Constants.headerBottomPadding)
        .padding(.horizontal, Constants.horizontalPadding)
    }

    private func totalView(viewData: YieldModuleClaimViewData) -> some View {
        Text(viewData.total)
            .style(DesignSystem.Font.displayMediumToken, color: DesignSystem.Color.textPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
    }

    private func rewardsAndFees(viewData: YieldModuleClaimViewData) -> some View {
        VStack(spacing: Constants.cardSpacing) {
            ForEach(viewData.sections) { section in
                YieldModuleClaimRewardsSectionView(section: section)
            }

            notificationView

            feesSection

            Text(Localization.yieldModuleClaimFooterNote)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Constants.footerNoteHorizontalPadding)
        }
    }

    @ViewBuilder
    private var notificationView: some View {
        if let notification = viewModel.notification {
            YieldModuleBottomSheetNotificationBannerView(params: notification)
        }
    }

    private var feesSection: some View {
        YieldModuleClaimFeesView(
            networkFeeState: viewModel.networkFeeState,
            serviceFeeState: viewModel.serviceFeeState,
            feeCurrencySymbol: viewModel.feeCurrencySymbol
        )
        .defaultRoundedBackground(
            with: DesignSystem.Color.bgTransparentPrimary,
            verticalPadding: .zero,
            horizontalPadding: .zero,
            cornerRadius: Constants.cardCornerRadius
        )
    }

    private func buttonBlock(viewData: YieldModuleClaimViewData) -> some View {
        mainButton(viewData: viewData)
            .padding(.top, 16)
            .padding(.horizontal, Constants.horizontalPadding)
            .padding(.bottom, Constants.buttonBottomPadding)
            .background(ListFooterOverlayShadowView())
    }

    @ViewBuilder
    private func mainButton(viewData: YieldModuleClaimViewData) -> some View {
        let title = Localization.yieldModuleClaimButtonTitle(viewData.total)

        if viewModel.confirmTransactionPolicy.needsHoldToConfirm {
            HoldToConfirmButton(
                title: title,
                isLoading: viewModel.isProcessingRequest,
                isDisabled: !viewModel.isActionButtonAvailable,
                action: viewModel.onClaimTap
            )
            .accessibilityIdentifier(YieldModuleAccessibilityIdentifiers.confirmButton)
        } else {
            MainButton(settings: .init(
                title: title,
                icon: viewModel.tangemIconProvider.getMainButtonIcon(),
                style: .primary,
                isLoading: viewModel.isProcessingRequest,
                isDisabled: !viewModel.isActionButtonAvailable,
                action: viewModel.onClaimTap
            ))
            .accessibilityIdentifier(YieldModuleAccessibilityIdentifiers.confirmButton)
        }
    }
}

// MARK: - Transition

private extension AnyTransition {
    static let content = AnyTransition.asymmetric(
        insertion: .opacity.animation(.curve(.easeInOutRefined, duration: 0.3)),
        removal: .opacity.animation(.curve(.easeInOutRefined, duration: 0.15))
    )
}

// MARK: - Animation

private extension Animation {
    static let contentFrameUpdate = Animation.curve(
        .easeInOutRefined,
        duration: YieldModuleClaimView.Constants.frameUpdateDuration
    )
}

// MARK: - Constants

private extension YieldModuleClaimView {
    enum Constants {
        static let horizontalPadding: CGFloat = 16
        static let footerNoteHorizontalPadding: CGFloat = 14
        static let buttonBottomPadding: CGFloat = 18
        static let frameUpdateDuration: TimeInterval = 0.5
        static let swipeDismissThreshold: CGFloat = 100
        static let maxHeightFraction: CGFloat = 0.9
        static let cardCornerRadius: CGFloat = 24
        static let cardSpacing: CGFloat = 8
        /// The toolbar row the design keeps at the top, whatever the two lines inside it measure.
        static let headerHeight: CGFloat = 44
        static let headerTextHorizontalInset: CGFloat = 52
        static let headerSpacing: CGFloat = 4
        static let headerTopPadding: CGFloat = 16
        static let headerBottomPadding: CGFloat = 16
        static let totalTopPadding: CGFloat = 24
        static let totalBottomPadding: CGFloat = 48
    }
}
