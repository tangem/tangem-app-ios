//
//  EthYieldSheetViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets
import TangemUI

final class EthYieldSheetViewModel: Identifiable {
    // [REDACTED_TODO_COMMENT]
    let title = "ETH yield"
    let activeRows: [RowItem]
    let inactiveRows: [RowItem]

    init(activeRows: [RowItem], inactiveRows: [RowItem]) {
        self.activeRows = activeRows
        self.inactiveRows = inactiveRows
    }
}

// MARK: - RowItem

extension EthYieldSheetViewModel {
    struct RowItem: Identifiable {
        let id: EarnYieldPickerProduct.ID
        let name: String
        let icon: Icon
        let content: Content
        let action: () -> Void
    }

    enum Icon {
        case logo(ImageType)
        case illustration(ImageType)
    }

    enum Content {
        case active(rate: String?, cryptoBalance: String, fiatBalance: String)
        case inactive(rate: String, risk: String)
    }
}
