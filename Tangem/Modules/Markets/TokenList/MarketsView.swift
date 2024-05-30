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
        .alert(item: $viewModel.alert, content: { $0.alert })
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Localization.manageTokensListHeaderTitle)
                .style(Fonts.Bold.title3, color: Colors.Text.primary1)
                .lineLimit(1)

            HStack {
                Button {} label: {
                    HStack {
                        Text("Raiting")
                            .style(Fonts.Bold.footnote, color: Colors.Text.primary1)

                        Assets
                            .arrowDownMini
                            .image
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Colors.Background.secondary)
                    )
                }

                Spacer()

                Picker("", selection: $viewModel.marketPriceInterval) {
                    ForEach(MarketPriceIntervalType.allCases, id: \.self) {
                        Text($0.rawValue)
                            .style(Fonts.Bold.footnote, color: Colors.Text.primary1)
                    }
                }
                .colorMultiply(Colors.Background.primary)
                .pickerStyle(.segmented)
                .frame(width: 152)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
    }

    private var list: some View {
        LazyVStack(spacing: 0) {
            ForEach(viewModel.tokenViewModels) {
                MarketsItemView(viewModel: $0)
            }

            if viewModel.isShowAddCustomToken {
                addCustomTokenView
            }

            if viewModel.hasNextPage, viewModel.viewDidAppear {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Colors.Icon.informative))
                    .onAppear(perform: viewModel.fetchMore)
            }
        }
    }

    private var addCustomTokenView: some View {
        MarketsAddCustomItemView {
            // Need force hide keyboard, because it will affect the state of the focus properties field in the shield under the hood
            UIApplication.shared.endEditing()

            viewModel.addCustomTokenDidTapAction()
        }
    }
}
