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

    // MARK: - View Body

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(viewModel.feeCurrencyTokens, id: \.self) {
                    FeeSelectorRowView(viewModel: $0)
                }
            }
            .padding(.horizontal, 16)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
    }
}
