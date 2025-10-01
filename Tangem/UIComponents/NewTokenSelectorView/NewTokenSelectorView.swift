//
//  NewTokenSelectorView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils
import TangemFoundation

struct NewTokenSelectorView: View {
    @ObservedObject var viewModel: NewTokenSelectorViewModel

    private var searchType: SearchType?

    init(viewModel: NewTokenSelectorViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        GroupedScrollView(spacing: 8) {
            content
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.viewState {
        case .empty:
            NewTokenSelectorViewEmptyContent()
        case .wallets(let wallets):
            ForEach(wallets) {
                NewTokenSelectorGroupedSectionView(viewModel: $0)
            }
        case .walletsWithAccounts(let walletsWithAccounts):
            ForEach(walletsWithAccounts) {
                NewTokenSelectorGroupedSectionWrapperView(viewModel: $0)
            }
        }
    }
}

struct NewTokenSelectorViewEmptyContent: View {
    var body: some View {
        Text("Empty")
    }
}

// MARK: - Setupable

extension NewTokenSelectorView: Setupable {
    func searchType(_ searchType: SearchType) -> Self {
        map { $0.searchType = searchType }
    }
}

extension NewTokenSelectorView {
    enum SearchType {
        case native
        case custom
    }
}
