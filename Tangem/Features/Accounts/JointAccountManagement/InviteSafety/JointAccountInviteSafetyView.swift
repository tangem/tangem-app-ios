//
//  JointAccountInviteSafetyView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

/// What sharing an invite means — read this before the link leaves the device.
struct JointAccountInviteSafetyView: View {
    let viewModel: JointAccountInviteSafetyViewModel

    var body: some View {
        points
            .footer { Footer(.buttons(primary: button)) }
    }

    private var points: some View {
        VStack(spacing: Constants.pointSpacing) {
            pointView(
                icon: DesignSystem.Icons.Lightning.regular20,
                title: Localization.jointAccountInviteMembersSafetyFirstPointTitle,
                message: Localization.jointAccountInviteMembersSafetyFirstPointSubtitle
            )

            pointView(
                icon: DesignSystem.Icons.Eye.regular20,
                title: Localization.jointAccountInviteMembersSafetySecondPointTitle,
                message: Localization.jointAccountInviteMembersSafetySecondPointSubtitle
            )

            pointView(
                icon: DesignSystem.Icons.Info.regular20,
                title: Localization.jointAccountInviteMembersSafetyThirdPointTitle,
                message: Localization.jointAccountInviteMembersSafetyThirdPointSubtitle
            )
        }
        .padding(.horizontal, Constants.pointsHorizontalPadding)
        .padding(.vertical, Constants.pointsVerticalPadding)
    }

    private func pointView(icon: ImageType, title: String, message: String) -> some View {
        HStack(alignment: .top, spacing: Constants.pointIconSpacing) {
            Circle()
                .fill(DesignSystem.Color.bgStatusInfoSubtle)
                .frame(size: Constants.pointIconBackgroundSize)
                .overlay {
                    icon.image
                        .renderingMode(.template)
                        .foregroundStyle(DesignSystem.Color.iconStatusInfo)
                }

            VStack(alignment: .leading, spacing: Constants.pointTextSpacing) {
                Text(title)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

                Text(message)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
            }
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var button: TangemUI.Button {
        TangemUI.Button(
            label: Localization.commonGotIt,
            accessibilityLabel: Localization.commonGotIt,
            action: viewModel.onCloseTap
        )
        .styleType(.primary)
    }
}

// MARK: - Constants

private extension JointAccountInviteSafetyView {
    enum Constants {
        static let pointsHorizontalPadding: CGFloat = 24
        static let pointsVerticalPadding: CGFloat = 22
        static let pointSpacing: CGFloat = 24
        static let pointIconSpacing: CGFloat = 12
        static let pointTextSpacing: CGFloat = 2
        static let pointIconBackgroundSize = CGSize(bothDimensions: 40)
    }
}

// MARK: - Previews

#Preview {
    Color.clear.modal(
        isPresented: .constant(true),
        contentLayout: .intrinsic,
        navigation: .title(Localization.jointAccountInviteMembersSafetySheetTitle)
    ) {
        JointAccountInviteSafetyView(viewModel: JointAccountInviteSafetyViewModel(coordinator: nil))
    }
}
