//
//  MainQRScanTokenSelectorAccountSectionView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct MainQRScanTokenSelectorAccountSectionView: View {
    @ObservedObject var viewModel: TokenSelectorAccountViewModel
    let headerOverride: TokenSelectorAccountViewModel.HeaderType?

    init(
        viewModel: TokenSelectorAccountViewModel,
        headerOverride: TokenSelectorAccountViewModel.HeaderType? = nil
    ) {
        self.viewModel = viewModel
        self.headerOverride = headerOverride
    }

    var body: some View {
        let availableItems = viewModel.compatibleItems
        let unavailableCount = viewModel.incompatibleItemsCount
        let rows = makeRows(availableItems: availableItems, unavailableCount: unavailableCount)

        GroupedSection(rows) { row in
            switch row {
            case .token(let item):
                TokenSelectorItemView(viewModel: item)
            case .incompatible(let count):
                MainQRScanTokenSelectorIncompatibleTokensRow(count: count)
            }
        } header: {
            TokenSelectorAccountHeaderView(header: headerOverride ?? viewModel.header)
        }
        .backgroundColor(Colors.Background.action)
    }

    private func makeRows(
        availableItems: [TokenSelectorItemViewModel],
        unavailableCount: Int
    ) -> [Row] {
        var rows = availableItems.map(Row.token)

        if unavailableCount > 0 {
            rows.append(.incompatible(unavailableCount))
        }

        return rows
    }

    private enum Row: Identifiable {
        case token(TokenSelectorItemViewModel)
        case incompatible(Int)

        var id: String {
            switch self {
            case .token(let item):
                return "token_\(item.id.id)"
            case .incompatible:
                return "incompatible"
            }
        }
    }
}
