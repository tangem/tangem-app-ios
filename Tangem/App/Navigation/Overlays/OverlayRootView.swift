//
//  OverlayRootView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct OverlayRootView: View {
    @ObservedObject var floatingSheetViewModel: FloatingSheetViewModel
    @ObservedObject var tangemStoriesViewModel: TangemStoriesViewModel

    var body: some View {
        EmptyView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .floatingSheet(
                viewModel: floatingSheetViewModel.activeSheet,
                dismissSheetAction: floatingSheetViewModel.removeActiveSheet
            )
    }
}
