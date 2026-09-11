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
        JointAccountIconMessage(
            icon: DesignSystem.Icons.ShieldCheckmark.filled28,
            iconColor: DesignSystem.Color.iconStatusInfo,
            iconBackgroundColor: DesignSystem.Color.bgStatusInfoSubtle,
            title: Localization.jointAccountJoinConfirmSheetTitle,
            message: Localization.jointAccountJoinConfirmSheetSubtitle
        )
    }

    private var buttons: some View {
        VStack(spacing: Constants.buttonSpacing) {
            TangemUI.Button(
                label: Localization.commonCancel,
                accessibilityLabel: Localization.commonCancel,
                action: viewModel.onCancelTap
            )
            .styleType(.secondary(.default))
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
        static let buttonSpacing: CGFloat = 8
    }
}

// MARK: - Previews

#Preview {
    JointAccountJoinConfirmationView(
        viewModel: JointAccountJoinConfirmationViewModel(
            userWalletModel: FakeUserWalletModel.wallet3Cards,
            preview: JointAccountInvitePreview(
                config: JointAccountSignedConfig(
                    name: "Family savings",
                    icon: AccountModel.CompositeIcon.Name.safe.rawValue,
                    iconColor: CompositeIconColor.candyGrapeFizz.rawValue,
                    membersCount: 5,
                    threshold: 2
                ),
                creator: JointAccountInvitePreview.Creator(
                    name: "Isaac",
                    address: "0xBef7B36845000000000000ac4e6752A9cE000000"
                )
            ),
            coordinator: nil
        )
    )
    .frame(maxHeight: .infinity, alignment: .bottom)
    .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
}
