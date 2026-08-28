//
//  JointAccountJoinConfirmationView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

/// The last stop before joining: what a shared account means for the funds.
struct JointAccountJoinConfirmationView: View {
    let viewModel: JointAccountJoinConfirmationViewModel

    var body: some View {
        VStack(spacing: .zero) {
            FloatingSheetNavigationBarView(
                backgroundColor: DesignSystem.Color.bgSecondary,
                closeButtonAction: viewModel.onCancelTap
            )

            content
                .padding(.horizontal, Constants.horizontalPadding)
                .padding(.vertical, Constants.contentVerticalPadding)

            buttons
                .padding(Constants.horizontalPadding)
        }
        .floatingSheetConfiguration {
            $0.sheetBackgroundColor = DesignSystem.Color.bgSecondary
            $0.backgroundInteractionBehavior = .tapToDismiss
        }
    }

    private var content: some View {
        VStack(spacing: Constants.iconSpacing) {
            icon

            VStack(spacing: Constants.textSpacing) {
                Text(Localization.jointAccountJoinConfirmSheetTitle)
                    .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)
                    .multilineTextAlignment(.center)

                Text(Localization.jointAccountJoinConfirmSheetSubtitle)
                    .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Constants.textHorizontalPadding)
        }
    }

    private var icon: some View {
        Circle()
            .fill(DesignSystem.Color.bgStatusInfoSubtle)
            .frame(size: Constants.iconBackgroundSize)
            .overlay {
                DesignSystem.Icons.ShieldCheckmark.filled28.image
                    .renderingMode(.template)
                    .foregroundStyle(DesignSystem.Color.iconStatusInfo)
            }
    }

    private var buttons: some View {
        VStack(spacing: Constants.buttonSpacing) {
            TangemUI.Button(
                label: Localization.commonCancel,
                accessibilityLabel: Localization.commonCancel,
                action: viewModel.onCancelTap
            )
            .styleType(.secondary)
            .size(.x12)
            .horizontalLayout(.infinity)

            TangemUI.Button(
                label: Localization.commonContinue,
                accessibilityLabel: Localization.commonContinue,
                action: viewModel.onContinueTap
            )
            .styleType(.default)
            .size(.x12)
            .horizontalLayout(.infinity)
        }
    }
}

// MARK: - Constants

private extension JointAccountJoinConfirmationView {
    enum Constants {
        static let horizontalPadding: CGFloat = 16
        static let contentVerticalPadding: CGFloat = 16
        static let iconSpacing: CGFloat = 32
        static let textSpacing: CGFloat = 8
        /// On top of the container's own padding, keeping the copy as narrow as the design has it.
        static let textHorizontalPadding: CGFloat = 32
        static let buttonSpacing: CGFloat = 8
        static let iconBackgroundSize = CGSize(bothDimensions: 72)
    }
}

// MARK: - Previews

#Preview {
    JointAccountJoinConfirmationView(
        viewModel: JointAccountJoinConfirmationViewModel(coordinator: nil)
    )
    .frame(maxHeight: .infinity, alignment: .bottom)
    .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
}
