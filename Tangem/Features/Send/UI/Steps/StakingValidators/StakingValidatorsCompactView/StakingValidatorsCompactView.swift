//
//  StakingValidatorsCompactView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI

struct StakingValidatorsCompactView: View {
    @ObservedObject var viewModel: StakingValidatorsCompactViewModel
    let type: SendCompactViewEditableType

    var body: some View {
        GroupedSection(viewModel.selectedValidator) { data in
            ValidatorCompactView(data: data)
        } header: {
            DefaultHeaderView(Localization.stakingValidator)
                .padding(.top, 12)
        }
        .settings(\.backgroundColor, Colors.Background.action)
        .readGeometry(\.size, bindTo: $viewModel.viewSize)
        .contentShape(Rectangle())
        .onTapGesture {
            if case .enabled(.some(let action)) = type {
                action()
            }
        }
    }
}
