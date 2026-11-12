//
//  PausedJointAccountRowView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemAccounts
import TangemAssets
import TangemLocalization
import TangemUI

struct PausedJointAccountRowView: View {
    @ObservedObject var viewModel: PausedJointAccountItemViewModel

    var body: some View {
        SwiftUI.Button(action: viewModel.onSelect) {
            Row(title: viewModel.name, subtitle: Localization.jointAccountMainPausedForSafety)
                .titleAccessory {
                    Badge(label: Localization.commonJoint, accessibilityLabel: nil)
                        .size(.x4)
                }
                .start {
                    AccountIconView(data: viewModel.iconData, settings: .defaultSized)
                }
                .overrideTextColors(RowOverrideTextColors(title: DesignSystem.Color.textSecondary))
                .includeInnerPadding(false)
                .contentShape(.rect)
        }
        .accessibilityIdentifier(AccountsAccessibilityIdentifiers.walletSettingsAccountRow(accountName: viewModel.name))
    }
}
