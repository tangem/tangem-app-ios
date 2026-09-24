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

    @State private var scrollContentHeight: CGFloat = 0
    @State private var buttonHeight: CGFloat = 0

    /// The sheet opens at its content height; once the content outgrows the screen, the system clamps that detent
    /// to the full-height one.
    private var detents: Set<PresentationDetent> {
        [.height(scrollContentHeight + buttonHeight), .large]
    }

    // MARK: - View Body

    var body: some View {
        VStack(spacing: .zero) {
            ScrollView(showsIndicators: false) {
                scrollContent
                    .padding(.horizontal, Constants.horizontalPadding)
                    .readGeometry(\.size.height) { scrollContentHeight = $0 }
            }
            .scrollBounceBehavior(.basedOnSize)

            buttonBlock
                .readGeometry(\.size.height) { buttonHeight = $0 }
        }
        .background(Colors.Background.tertiary.ignoresSafeArea())
        .presentationDetents(detents)
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(Constants.cornerRadius)
        .interactiveDismissDisabled(viewModel.isProcessingRequest)
    }

    // MARK: - Sub Views

    private var scrollContent: some View {
        VStack(spacing: .zero) {
            Text(Localization.yieldModuleClaimSheetTitle)
                .style(Fonts.Bold.title2, color: Colors.Text.primary1)
                .multilineTextAlignment(.center)
                .padding(.top, 14)

            Text(Localization.yieldModuleClaimSheetSubtitle)
                .style(Fonts.Regular.subheadline, color: Colors.Text.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)

            totalView
                .padding(.top, 16)

            rewardsAndFees
                .padding(.top, 24)
        }
    }

    private var totalView: some View {
        Text(viewModel.viewData.total)
            .style(Fonts.Bold.largeTitle, color: Colors.Text.primary1)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
    }

    private var rewardsAndFees: some View {
        VStack(spacing: 12) {
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
        .defaultRoundedBackground(with: Colors.Background.action)
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
        static let cornerRadius: CGFloat = 24
    }
}
