//
//  MultiWalletMainContentAccountSection.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

typealias MultiWalletMainContentAccountSection = SectionModel<ExpandableAccountItemViewModel, MultiWalletMainContentPlainSection>

// MARK: - Convenience extensions

extension Array where Element == MultiWalletMainContentAccountSection {
    var flattenedTokenItems: [TokenItemViewModel] {
        flatMap(\.items.flattenedTokenItems)
    }
}
