//
//  MainBottomSheetHeaderContainerView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

/// A temporary entity for integration and testing, subject to change.
struct MainBottomSheetHeaderContainerView: View {
    @ObservedObject var viewModel: MainBottomSheetViewModel

    var body: some View {
        MainBottomSheetHeaderView(searchText: $viewModel.searchText, textFieldAllowsHitTesting: true)
    }
}
