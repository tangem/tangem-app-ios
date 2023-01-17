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

    private let separatorInset: CGFloat = 52 // 40(icon) + 12(padding)

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

                Spacer().frame(height: 12)

                userItemsSection()

                Spacer().frame(height: 12)

                otherItemsSection()

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

    func userItemsSection() -> some View {
        Group {
            Text(Localization.swappingTokenListYourTokens.uppercased())
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

            ForEach(viewModel.userItems) { model in
                SwappingTokenItemView(viewModel: model)

                if viewModel.userItems.last?.id != model.id {
                    Separator(color: Colors.Stroke.primary)
                        .padding(.leading, separatorInset)
                }
            }
        }
    }

    func otherItemsSection() -> some View {
        Group {
            Text(Localization.swappingTokenListOtherTokens.uppercased())
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

            ForEach(viewModel.otherItems) { model in
                SwappingTokenItemView(viewModel: model)

                if viewModel.otherItems.last?.id != model.id {
                    Separator(color: Colors.Stroke.primary)
                        .padding(.leading, separatorInset)
                }
            }
        }
    }
}
