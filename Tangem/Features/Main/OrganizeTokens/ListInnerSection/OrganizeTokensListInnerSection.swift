//
//  OrganizeTokensListInnerSection.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

typealias OrganizeTokensListInnerSection = SectionModel<OrganizeTokensListInnerSectionViewModel, OrganizeTokensListItemViewModel>

// MARK: - Convenience extensions

extension OrganizeTokensListInnerSection {
    var isDraggable: Bool {
        if case .draggable = model.style {
            return true
        }
        return false
    }
}
