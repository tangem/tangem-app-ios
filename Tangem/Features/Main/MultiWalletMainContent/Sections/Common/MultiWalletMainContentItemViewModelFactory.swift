//
//  MultiWalletMainContentItemViewModelFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol MultiWalletMainContentItemViewModelFactory: AnyObject {
    func makeTokenItemViewModel(
        from sectionItem: TokenSectionsAdapter.SectionItem,
        using sectionItemsFactory: MultiWalletSectionItemsFactory
    ) -> TokenItemViewModel
}
