//
//  OrganizeTokensListSection.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemAccounts // [REDACTED_TODO_COMMENT]

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

// [REDACTED_TODO_COMMENT]
typealias _OrganizeTokensListSection = SectionModel<_AccountModel, OrganizeTokensListSection>

// [REDACTED_TODO_COMMENT]
struct _AccountModel {
    let name: String
    let iconData: AccountIconView.ViewData
}
