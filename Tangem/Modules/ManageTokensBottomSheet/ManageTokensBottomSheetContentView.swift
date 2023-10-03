//
//  ManageTokensBottomSheetContentView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

#if ALPHA_OR_BETA
@available(*, deprecated, message: "Test only, remove if not needed")
struct ManageTokensBottomSheetContentView: View {
    @ObservedObject private var viewModel: ManageTokensBottomSheetViewModel

    init(
        viewModel: ManageTokensBottomSheetViewModel
    ) {
        self.viewModel = viewModel
    }

    var body: some View {
        // [REDACTED_TODO_COMMENT]
        LazyVStack(spacing: .zero) {
            ForEach(viewModel.dataSource(), id: \.self) { index in
                Button(action: viewModel.toggleItem) {
                    Text(index)
                        .font(.title3)
                        .foregroundColor(Colors.Text.primary1.opacity(0.8))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.all)
                }
                .background(Colors.Background.primary)

                Divider()
            }
        }
    }
}
#endif // ALPHA_OR_BETA
