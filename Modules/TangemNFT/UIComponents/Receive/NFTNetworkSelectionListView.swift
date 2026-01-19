//
//  NFTNetworkSelectionListView.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

public struct NFTNetworkSelectionListView: View {
    @ObservedObject private var viewModel: NFTNetworkSelectionListViewModel

    @State private var searchFieldDisplayMode: SearchFieldPlacement.NavigationBarDrawerDisplayMode = .always

    public var body: some View {
        listContent
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CloseTextButton(action: viewModel.onCloseButtonTap)
                }

                ToolbarItem(placement: .principal) {
                    navigationBarTitle
                }
            }
            .background(Colors.Background.tertiary)
            .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: searchFieldDisplayMode))
            .bindAlert($viewModel.alert)
            .onAppear {
                viewModel.onViewAppear()
                // Workaround for iOS 15 and 17 bug with incorrect search field layout in navigation bar drawer on initial appear
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    searchFieldDisplayMode = .automatic
                }
            }
    }

    private var navigationBarTitle: some View {
        VStack(spacing: 4.0) {
            Text(viewModel.title)
                .style(Fonts.Bold.body.weight(.semibold), color: Colors.Text.primary1)

            Text(viewModel.subtitle)
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
        }
    }

    private var listContent: some View {
        GroupedScrollView(contentType: .lazy(alignment: .center, spacing: 12.0)) {
            GroupedSection(
                viewModel.allItems,
                content: { item in
                    makeSectionItemView(item)
                },
                header: {
                    makeSectionTitle(Localization.nftReceiveChooseNetwork)
                }
            )
            .settings(\.separatorStyle, .none)
            .settings(\.backgroundColor, Colors.Background.action)

            GroupedSection(
                viewModel.availableItems,
                content: { item in
                    makeSectionItemView(item)
                },
                header: {
                    makeSectionTitle(Localization.nftReceiveAvailableSectionTitle)
                }
            )
            .settings(\.separatorStyle, .none)
            .settings(\.backgroundColor, Colors.Background.action)

            GroupedSection(
                viewModel.unavailableItems,
                content: { item in
                    makeSectionItemView(item)
                },
                header: {
                    makeSectionTitle(Localization.nftReceiveUnavailableSectionTitle)
                }
            )
            .settings(\.separatorStyle, .none)
            .settings(\.backgroundColor, Colors.Background.action)
        }
        .scrollIndicators(.hidden)
    }

    public init(viewModel: NFTNetworkSelectionListViewModel) {
        self.viewModel = viewModel
    }

    private func makeSectionItemView(_ viewData: NFTNetworkSelectionListItemViewData) -> some View {
        Button(action: viewData.tapAction) {
            NFTNetworkSelectionListItemView(viewData: viewData)
        }
    }

    private func makeSectionTitle(_ title: String) -> some View {
        Text(title)
            .style(Fonts.Bold.footnote.weight(.semibold), color: Colors.Text.tertiary)
            .padding(.top, 12.0)
            .padding(.bottom, 8.0)
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    NavigationStack {
        NFTNetworkSelectionListView(
            viewModel: .init(
                userWalletName: "Test Wallet",
                dataSource: NFTNetworkSelectionListDataSourceMock(),
                tokenIconInfoProvider: NFTTokenIconInfoProviderMock(),
                nftChainNameProviding: NFTChainNameProviderMock(),
                analytics: .empty,
                coordinator: nil
            )
        )
    }
}
#endif // DEBUG
