//
//  OrganizeTokensListSection.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

typealias OrganizeTokensListSection = SectionModel<OrganizeTokensListSectionViewModel, OrganizeTokensListItemViewModel>

// MARK: - Convenience extensions

extension OrganizeTokensListSection {
    var isDraggable: Bool {
        if case .draggable = model.style {
            return true
        }
        return false
    }
}
