//
//  StakingRegionUnavailableSheetView.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct StakingRegionUnavailableSheetView: View {
    let viewModel: StakingRegionUnavailableSheetViewModel

    var body: some View {
        BottomSheetErrorContentView(
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
