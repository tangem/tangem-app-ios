//
//  MarketsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import BlockchainSdk

struct MarketsView: View {
    @ObservedObject var viewModel: MarketsViewModel

    var body: some View {
        VStack {
            header

            list
        }
        .scrollDismissesKeyboardCompat(.immediately)
        .background(Colors.Background.primary)
        .alert(item: $viewModel.alert, content: { $0.alert })
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Localization.marketsCommonTitle)
                .style(Fonts.Bold.title3, color: Colors.Text.primary1)
                .lineLimit(1)

            MarketsRatingHeaderView(viewModel: viewModel.marketsRatingHeaderViewModel)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.tokenViewModels) {
                    MarketsItemView(viewModel: $0)
                }

                // Need for display list skeleton view
                if viewModel.isLoading {
                    ForEach(0 ..< 20) { _ in
                        MarketsSkeletonItemView()
                    }
                }
            }
        }
    }
}
