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
    @ObservedObject var viewModel: AccountsAwareTokenSelectorAccountViewModel
    let headerOverride: AccountsAwareTokenSelectorAccountViewModel.HeaderType?

    init(
        viewModel: AccountsAwareTokenSelectorAccountViewModel,
        headerOverride: AccountsAwareTokenSelectorAccountViewModel.HeaderType? = nil
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
                AccountsAwareTokenSelectorItemView(viewModel: item)
            case .incompatible(let count):
                MainQRScanTokenSelectorIncompatibleTokensRow(count: count)
            }
        } header: {
            AccountsAwareTokenSelectorAccountHeaderView(header: headerOverride ?? viewModel.header)
        }
        .backgroundColor(Colors.Background.action)
    }

    private func makeRows(
        availableItems: [AccountsAwareTokenSelectorItemViewModel],
        unavailableCount: Int
    ) -> [Row] {
        var rows = availableItems.map(Row.token)

        if unavailableCount > 0 {
            rows.append(.incompatible(unavailableCount))
        }

        return rows
    }

    private enum Row: Identifiable {
        case token(AccountsAwareTokenSelectorItemViewModel)
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
