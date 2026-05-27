//
//  FloatingSheetRegistry+MarketsSearch.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemUI

extension FloatingSheetRegistry {
    func registerMarketsSearchFloatingSheets() {
        register(MarketsPortfolioTokenListViewModel.self) {
            MarketsPortfolioTokenListView(viewModel: $0)
        }
    }
}
