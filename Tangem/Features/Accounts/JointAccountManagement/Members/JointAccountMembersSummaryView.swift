//
//  JointAccountMembersSummaryView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccounts
import TangemAssets
import TangemLocalization
import TangemUI

struct JointAccountMembersSummaryView: View {
    let summary: JointAccountMembersViewModel.Summary
    let onApprovalsInfoTap: () -> Void

    var body: some View {
        VStack(spacing: .zero) {
            Row(title: summary.name, subtitle: summary.membersCount)
                .start { AccountIconView(data: summary.iconViewData) }
                .showDivider()

            Row(title: Localization.jointAccountInviteMembersRequiredApprovals, value: summary.requiredApprovals)
                .valueAccessory { approvalsInfoIcon }
                .overrideTextColors(RowOverrideTextColors(value: DesignSystem.Color.textSecondary))
                .onTap(action: onApprovalsInfoTap)
                .accessibilityHint(Localization.jointAccountInviteMembersAboutSignaturesTitle)
        }
        .background(DesignSystem.Color.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius, style: .continuous))
    }

    private var approvalsInfoIcon: some View {
        DesignSystem.Icons.Info.regular20.image
            .renderingMode(.template)
            .foregroundStyle(DesignSystem.Color.iconSecondary)
            .accessibilityHidden(true)
    }
}

// MARK: - Constants

private extension JointAccountMembersSummaryView {
    enum Constants {
        static let cornerRadius: CGFloat = 24
    }
}
