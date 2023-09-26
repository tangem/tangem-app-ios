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
            .frame(height: 46.0)
            .padding(.horizontal, 12.0)
            .background(Colors.Field.primary)
            .cornerRadius(14.0)
            .padding(.init(top: 20.0, leading: 16.0, bottom: 34.0, trailing: 16.0)) // [REDACTED_TODO_COMMENT]
            .background(Colors.Background.primary)
    }
}
