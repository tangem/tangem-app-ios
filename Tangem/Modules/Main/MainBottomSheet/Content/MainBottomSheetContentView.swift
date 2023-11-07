//
//  MainBottomSheetContentView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

/// A temporary entity for integration and testing, subject to change.
struct MainBottomSheetContentView: View {
    @ObservedObject var viewModel: MainBottomSheetContentViewModel

    var body: some View {
        if let manageTokensViewModel = viewModel.manageTokensViewModel {
            ManageTokensView(viewModel: manageTokensViewModel)
                .onAppear { manageTokensViewModel.onAppear() }
        }
    }
}
