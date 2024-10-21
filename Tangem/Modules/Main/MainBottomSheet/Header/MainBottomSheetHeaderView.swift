//
//  MainBottomSheetHeaderView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct MainBottomSheetHeaderView: View {
    @ObservedObject var viewModel: MainBottomSheetHeaderViewModel

    var body: some View {
        MainBottomSheetHeaderInputView(
            searchText: $viewModel.enteredSearchText,
            isTextFieldFocused: $viewModel.inputShouldBecomeFocused,
            allowsHitTestingForTextField: true,
            clearButtonAction: viewModel.clearSearchBarAction
        )
    }
}
