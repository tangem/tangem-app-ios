//
//  ManageTokensView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import BlockchainSdk
import AlertToast

struct ManageTokensView: View {
    @ObservedObject var viewModel: ManageTokensViewModel

    var body: some View {
        list
            .scrollDismissesKeyboardCompat(true)
            .alert(item: $viewModel.alert, content: { $0.alert })
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Coin market cap")
                .style(Fonts.Bold.title1, color: Colors.Text.primary1)
                .lineLimit(1)

            Text("Couldn’t find this token, you can add it manually")
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                .lineLimit(1)
        }
        .frame(
            maxWidth: .infinity,
            alignment: .topLeading
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    private var list: some View {
        LazyVStack(spacing: 0) {
            header

            ForEach(viewModel.tokenViewModels) {
                ManageTokensItemView(viewModel: $0)
            }

            if viewModel.hasNextPage {
                HStack(alignment: .center) {
                    ActivityIndicatorView(color: .gray)
                        .onAppear(perform: viewModel.batch)
                }
            }
        }
    }

    @ViewBuilder private var titleView: some View {
        Text(Localization.addTokensTitle)
            .style(Fonts.Bold.title1, color: Colors.Text.primary1)
    }
}
