//
//  FeeSelectorTokensView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct FeeSelectorTokensView: View {
    @ObservedObject var viewModel: FeeSelectorTokensViewModel

    // [REDACTED_TODO_COMMENT]
    var body: some View {
        Button {
            viewModel.userDidSelectFeeToken()
        } label: {
            Text("Some token")
        }
        .padding()
    }
}
