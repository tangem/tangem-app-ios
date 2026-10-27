//
//  StakingTargetsCompactView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI

struct StakingTargetsCompactView: View {
    @ObservedObject var viewModel: StakingTargetsCompactViewModel

    var body: some View {
        GroupedSection(viewModel.selectedTarget) { data in
            StakingTargetCompactView(data: data)
        } header: {
            DefaultHeaderView(Localization.stakingValidator)
                .padding(.top, 12)
        }
        .settings(\.backgroundColor, DesignSystem.Color.bgSecondary)
        .contentShape(Rectangle())
    }
}
