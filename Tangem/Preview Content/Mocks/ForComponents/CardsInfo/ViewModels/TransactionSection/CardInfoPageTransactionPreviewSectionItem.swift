//
//  CardInfoPageTransactionPreviewSectionItem.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

/// Example of a `List` section that contains only one type of item.
enum CardInfoPageTransactionPreviewSectionItem {
    case `default`(CardInfoPageTransactionDefaultCellPreviewViewModel)
}

// MARK: - Identifiable protocol conformance

extension CardInfoPageTransactionPreviewSectionItem: Identifiable {
    var id: UUID {
        switch self {
        case .default(let viewModel):
            return viewModel.id
        }
    }
}
