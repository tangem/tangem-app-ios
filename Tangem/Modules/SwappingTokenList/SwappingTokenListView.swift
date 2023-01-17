//
//  SwappingTokenListView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct SwappingTokenListView: View {
    @ObservedObject private var viewModel: SwappingTokenListViewModel

    // 40(icon) + 12(padding) from SwappingTokenItemView
    private let separatorInset: CGFloat = 52

    init(viewModel: SwappingTokenListViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            GroupedScrollView(alignment: .leading, spacing: 0) {
                if #available(iOS 15.0, *) {} else {
                    let horizontalInset: CGFloat = UIDevice.isIOS13 ? 8 : 16
                    SearchBar(text: $viewModel.searchText.value, placeholder: Localization.commonSearch)
                        .padding(.horizontal, UIDevice.isIOS13 ? 0 : 8)
                        .listRowInsets(.init(top: 8, leading: horizontalInset, bottom: 8, trailing: horizontalInset))
                }

                FixedSpacer(height: 12)

                section(
                    title: Localization.swappingTokenListYourTokens.uppercased(),
                    items: viewModel.userItems
                )

                FixedSpacer(height: 12)

                section(
                    title: Localization.swappingTokenListOtherTokens.uppercased(),
                    items: viewModel.otherItems
                )

                if viewModel.hasNextPage {
                    ProgressViewCompat(color: Colors.Icon.informative)
                        .onAppear(perform: viewModel.fetch)
                        .frame(alignment: .center)
                }
            }
            .searchableCompat(text: $viewModel.searchText.value)
            .navigationBarTitle(Text(Localization.swappingTokenListYourTitle), displayMode: .inline)
        }
    }

    func section(title: String, items: [SwappingTokenItemViewModel]) -> some View {
        Group {
            Text(title)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

            ForEach(items) { item in
                SwappingTokenItemView(viewModel: item)

                if items.last?.id != item.id {
                    Separator(color: Colors.Stroke.primary)
                        .padding(.leading, separatorInset)
                }
            }
        }
    }
}
