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

    private var separatorInset: CGFloat {
        SwappingTokenItemView.iconSize.width + SwappingTokenItemView.horizontalInteritemSpacing
    }

    init(viewModel: SwappingTokenListViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            GroupedScrollView(alignment: .center, spacing: 0) {
                if #unavailable(iOS 15.0) {
                    let horizontalInset: CGFloat = UIDevice.isIOS13 ? 8 : 16
                    SearchBar(text: $viewModel.searchText.value, placeholder: Localization.commonSearch)
                        .padding(.horizontal, UIDevice.isIOS13 ? 0 : 8)
                        .listRowInsets(.init(top: 8, leading: horizontalInset, bottom: 8, trailing: horizontalInset))
                }

                FixedSpacer(height: 12)

                section(type: .userItems, items: viewModel.userItems)

                FixedSpacer(height: 12)

                section(type: .otherItems, items: viewModel.otherItems)

                if viewModel.hasNextPage {
                    ProgressViewCompat(color: Colors.Icon.informative)
                        .onAppear(perform: viewModel.fetch)
                }
            }
            .searchableCompat(text: $viewModel.searchText.value)
            .modifier(ifLet: viewModel.navigationTitleViewModel) { view, viewModel in
                if #available(iOS 14.0, *) {
                    view
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .principal) {
                                BlockchainNetworkNavigationTitleView(viewModel: viewModel)
                            }
                        }
                } else {
                    view
                        .navigationBarTitle(Text(Localization.swappingTokenListTitle), displayMode: .inline)
                }
            }
        }
    }

    @ViewBuilder
    func section(type: SectionType, items: [SwappingTokenItemViewModel]) -> some View {
        if !items.isEmpty {
            Text(type.title.uppercased())
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                .frame(maxWidth: .infinity, alignment: .leading)

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

extension SwappingTokenListView {
    enum SectionType {
        case userItems
        case otherItems

        var title: String {
            switch self {
            case .userItems:
                return Localization.swappingTokenListYourTokens
            case .otherItems:
                return Localization.swappingTokenListOtherTokens
            }
        }
    }
}
