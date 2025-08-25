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
    @ObservedObject var alertPresenterViewModel: AlertPresenterViewModel

    var body: some View {
        EmptyView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .floatingSheet(
                viewModel: floatingSheetViewModel.activeSheet,
                dismissSheetAction: floatingSheetViewModel.removeActiveSheet
            )
            .alert(item: $alertPresenterViewModel.alert) { $0.alert }
    }
}
