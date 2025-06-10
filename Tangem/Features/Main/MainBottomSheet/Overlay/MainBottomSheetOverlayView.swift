//
//  MainBottomSheetOverlayView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct MainBottomSheetOverlayView: View {
    let viewModel: MainBottomSheetOverlayViewModel

    var body: some View {
        switch viewModel {
        case .generateAddresses(let viewModel):
            GenerateAddressesView(viewModel: viewModel)
                .overlay(alignment: .top) {
                    // Covers transparent hole caused by the bottom scrollable sheet overscroll,
                    // 2.0 pt constant ensures that some overlapping exists between neighboring views
                    Colors.Background.action
                        .alignmentGuide(.top) { -$0.height + 2.0 }
                }
        }
    }
}
