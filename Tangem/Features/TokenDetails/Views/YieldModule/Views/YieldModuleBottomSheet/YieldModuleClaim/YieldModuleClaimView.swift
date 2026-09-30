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
        ScrollView(showsIndicators: false) {
            scrollContent
                .padding(.horizontal, Constants.horizontalPadding)
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom, spacing: .zero) {
            buttonBlock
        }
        .floatingSheetConfiguration { configuration in
            configuration.sheetBackgroundColor = DesignSystem.Color.bgSecondary
            configuration.backgroundInteractionBehavior = viewModel.isProcessingRequest ? .consumeTouches : .tapToDismiss
            configuration.verticalSwipeBehavior = viewModel.isProcessingRequest
                ? nil
                : .init(target: .sheet, threshold: Constants.swipeDismissThreshold)
        }
        .accessibilityAction(.escape) {
            guard !viewModel.isProcessingRequest else { return }

            viewModel.onCloseTap()
        }
    }

    // MARK: - Sub Views

    private var scrollContent: some View {
        VStack(spacing: .zero) {
            headerView

            totalView
                .padding(.top, Constants.totalTopPadding)
                .padding(.bottom, Constants.totalBottomPadding)

            rewardsAndFees
        }
    }

    private var headerView: some View {
        VStack(spacing: Constants.headerSpacing) {
            Text(Localization.yieldModuleClaimSheetTitle)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

            Text(Localization.yieldModuleClaimSheetSubtitle)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
        }
        .multilineTextAlignment(.center)
        .frame(minHeight: Constants.headerHeight)
        .padding(.top, Constants.headerTopPadding)
        .padding(.bottom, Constants.headerBottomPadding)
    }

    private var totalView: some View {
        Text(viewModel.viewData.total)
            .style(DesignSystem.Font.displayMediumToken, color: DesignSystem.Color.textPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
    }

    private var rewardsAndFees: some View {
        VStack(spacing: Constants.cardSpacing) {
            ForEach(viewModel.viewData.sections) { section in
                YieldModuleClaimRewardsSectionView(section: section)
            }

            notificationView

            feesSection

            notesView

            Text(Localization.yieldModuleClaimFooterNote)
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 14)
        }
    }

    @ViewBuilder
    private var notificationView: some View {
        if let notification = viewModel.notification {
            YieldModuleBottomSheetNotificationBannerView(params: notification)
        }
    }

    private var feesSection: some View {
        VStack(spacing: 12) {
            YieldFeeSection(
                sectionState: viewModel.serviceFeeState,
                leadingTitle: Localization.yieldModuleClaimServiceFeeTitle,
                needsBackground: false
            )

            Separator(color: Colors.Stroke.primary)
                .padding(.horizontal, 4)

            YieldFeeSection(
                sectionState: viewModel.networkFeeState,
                leadingTitle: Localization.commonNetworkFeeTitle,
                needsBackground: false
            )
        }
        .defaultRoundedBackground(
            with: DesignSystem.Color.bgTransparentPrimary,
            cornerRadius: Constants.cardCornerRadius
        )
    }

    private var notesView: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let serviceFeeNote = viewModel.serviceFeeNote {
                Text(serviceFeeNote)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
            }

            Text(Localization.yieldModuleClaimEstimatedAmountsNote)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
    }

    private var buttonBlock: some View {
        mainButton
            .padding(.top, 16)
            .padding(.horizontal, Constants.horizontalPadding)
            .padding(.bottom, 18)
            .background(ListFooterOverlayShadowView())
    }

    @ViewBuilder
    private var mainButton: some View {
        if viewModel.confirmTransactionPolicy.needsHoldToConfirm {
            HoldToConfirmButton(
                title: viewModel.buttonTitle,
                isLoading: viewModel.isProcessingRequest,
                isDisabled: !viewModel.isActionButtonAvailable,
                action: viewModel.onClaimTap
            )
            .accessibilityIdentifier(YieldModuleAccessibilityIdentifiers.confirmButton)
        } else {
            MainButton(settings: .init(
                title: viewModel.buttonTitle,
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

// MARK: - Constants

private extension YieldModuleClaimView {
    enum Constants {
        static let horizontalPadding: CGFloat = 16
        static let swipeDismissThreshold: CGFloat = 100
        static let cardCornerRadius: CGFloat = 24
        static let cardSpacing: CGFloat = 8
        /// The toolbar row the design keeps at the top, whatever the two lines inside it measure.
        static let headerHeight: CGFloat = 44
        static let headerSpacing: CGFloat = 4
        static let headerTopPadding: CGFloat = 16
        static let headerBottomPadding: CGFloat = 16
        static let totalTopPadding: CGFloat = 24
        static let totalBottomPadding: CGFloat = 48
    }
}
