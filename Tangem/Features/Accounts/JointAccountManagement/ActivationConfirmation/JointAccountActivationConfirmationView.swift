//
//  JointAccountActivationConfirmationView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

/// The last stop before activating: what a shared balance means once the account starts working.
struct JointAccountActivationConfirmationView: View {
    let viewModel: JointAccountActivationConfirmationViewModel

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
        JointAccountIconMessage(
            icon: DesignSystem.Icons.ShieldCheckmark.filled28,
            iconColor: DesignSystem.Color.iconStatusInfo,
            iconBackgroundColor: DesignSystem.Color.bgStatusInfoSubtle,
            title: Localization.jointAccountActivationTitle,
            message: Localization.jointAccountActivationSubtitle
        )
    }

    /// - Note: The affirmative button leads, unlike the joining sheet, where it follows the cancelling one. Both
    /// platforms lay the two sheets out this way.
    private var buttons: some View {
        VStack(spacing: Constants.buttonSpacing) {
            TangemUI.Button(
                label: Localization.commonActivate,
                accessibilityLabel: Localization.commonActivate,
                action: viewModel.onActivateTap
            )
            .iconEnd(viewModel.hasNFCInteraction ? DesignSystem.Icons.LogoTangem.regular24 : nil)
            .styleType(.default)
            .size(.x12)
            .horizontalLayout(.infinity)

            TangemUI.Button(
                label: Localization.commonCancel,
                accessibilityLabel: Localization.commonCancel,
                action: viewModel.onCancelTap
            )
            .styleType(.secondary(.default))
            .size(.x12)
            .horizontalLayout(.infinity)
        }
    }
}

// MARK: - Constants

private extension JointAccountActivationConfirmationView {
    enum Constants {
        static let horizontalPadding: CGFloat = 16
        static let contentVerticalPadding: CGFloat = 16
        static let buttonSpacing: CGFloat = 8
    }
}

// MARK: - Previews

#Preview {
    JointAccountActivationConfirmationView(
        viewModel: JointAccountActivationConfirmationViewModel(hasNFCInteraction: true, onConfirm: {}, coordinator: nil)
    )
    .frame(maxHeight: .infinity, alignment: .bottom)
    .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
}
