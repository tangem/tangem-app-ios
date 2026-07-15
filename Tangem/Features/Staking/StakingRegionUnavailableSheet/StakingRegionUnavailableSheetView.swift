//
//  StakingRegionUnavailableSheetView.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct StakingRegionUnavailableSheetView: View {
    let viewModel: StakingRegionUnavailableSheetViewModel

    var body: some View {
        BottomSheetErrorContentView(
            icon: .init(
                icon: DesignSystem.Icons.Error.regular28,
                overlay: DesignSystem.Color.iconStatusWarning,
                tint: DesignSystem.Color.iconStatusWarning
            ),
            title: viewModel.title,
            subtitle: viewModel.subtitle,
            closeAction: viewModel.close,
            primaryButton: viewModel.primaryButtonSettings
        )
        .floatingSheetConfiguration { configuration in
            configuration.backgroundInteractionBehavior = .tapToDismiss
        }
    }
}
