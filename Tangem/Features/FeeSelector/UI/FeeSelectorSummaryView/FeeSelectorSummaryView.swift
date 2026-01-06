//
//  FeeSelectorSummaryView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct FeeSelectorSummaryView: View {
    @ObservedObject var viewModel: FeeSelectorSummaryViewModel

    // [REDACTED_TODO_COMMENT]
    var body: some View {
        VStack {
            Button {
                viewModel.userDidTapToken()
            } label: {
                Text("Select token")
            }
            .padding()

            Button {
                viewModel.userDidTapFee()
            } label: {
                Text("Select fee")
            }
            .padding()
        }
    }
}
