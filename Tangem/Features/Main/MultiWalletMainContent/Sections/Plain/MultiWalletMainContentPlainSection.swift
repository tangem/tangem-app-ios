//
//  MultiWalletMainContentPlainSection.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

typealias MultiWalletMainContentPlainSection = SectionModel<MultiWalletMainContentPlainSectionViewModel, TokenItemViewModel>

// MARK: - Convenience extensions

extension Array where Element == MultiWalletMainContentPlainSection {
    var flattenedTokenItems: [TokenItemViewModel] {
        flatMap(\.items)
    }
}
