//
//  SwappingTokenListView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import BlockchainSdk

struct SwappingTokenListView: View {
    @ObservedObject private var viewModel: SwappingTokenListViewModel

    init(viewModel: SwappingTokenListViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            PerfList {
                if #available(iOS 15.0, *) {} else {
                    let horizontalInset: CGFloat = UIDevice.isIOS13 ? 8 : 16
                    SearchBar(text: $viewModel.searchText.value, placeholder: "common_search".localized)
                        .padding(.horizontal, UIDevice.isIOS13 ? 0 : 8)
                        .listRowInsets(.init(top: 8, leading: horizontalInset, bottom: 8, trailing: horizontalInset))
                }

                GroupedSection(viewModel.yourItems) {
                    SwappingTokenItemView(viewModel: $0)
                } header: {
                    Text("your tokens".uppercased())
                        .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                }
                .separatorPadding(68)

                GroupedSection(viewModel.otherItems) {
                    SwappingTokenItemView(viewModel: $0)
                } header: {
                    Text("other tokens".uppercased())
                        .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                }
                .separatorPadding(68)

                if viewModel.hasNextPage {
                    ProgressViewCompat(color: Colors.Icon.informative)
                        .onAppear(perform: viewModel.fetch)
                        .frame(alignment: .center)
                }
            }
            .searchableCompat(text: $viewModel.searchText.value)
            .navigationBarTitle(Text("Choose token"), displayMode: .inline)
        }
    }
}

struct SwappingTokenListView_Preview: PreviewProvider {
    static let viewModel = SwappingTokenListViewModel(
        networkIds: Blockchain.supportedBlockchains.map { $0.networkId },
        coordinator: nil
    )

    static var previews: some View {
        NavigationView {
            SwappingTokenListView(viewModel: viewModel)
        }
    }
}
