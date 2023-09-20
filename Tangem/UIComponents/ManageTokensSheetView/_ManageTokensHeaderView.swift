//
//  _ManageTokensHeaderView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

// [REDACTED_TODO_COMMENT]
struct _ManageTokensHeaderView: View {
    @ObservedObject private var viewModel: ManageTokensSheetViewModel // [REDACTED_TODO_COMMENT]

    init(
        viewModel: ManageTokensSheetViewModel
    ) {
        self.viewModel = viewModel
    }

    var body: some View {
        TextField("Placeholder", text: $viewModel.searchText)
            .frame(height: 46)
            .padding(.horizontal, 12)
            .background(Colors.Field.primary)
            .cornerRadius(14)
            .padding(.horizontal, 16)
            .padding(.bottom, 21.0)
            .padding(.bottom, 34.0 - 21.0) // [REDACTED_TODO_COMMENT]
    }
}
