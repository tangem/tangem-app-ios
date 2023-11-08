//
//  MainBottomSheetHeaderContainerView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct MainBottomSheetHeaderContainerView: View {
    @ObservedObject var viewModel: MainBottomSheetHeaderViewModel

    var body: some View {
        MainBottomSheetHeaderView(searchText: $viewModel.enteredSearchText, textFieldAllowsHitTesting: true)
    }
}
