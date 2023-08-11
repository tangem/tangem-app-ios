//
//  OrganizeTokensListSectionViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct OrganizeTokensListSectionViewModel: Equatable, Identifiable {
    enum SectionStyle: Hashable {
        case invisible
        case fixed(title: String)
        case draggable(title: String)
    }

    let id: UUID
    let style: SectionStyle
    var items: [OrganizeTokensListItemViewModel]

    var isDraggable: Bool {
        if case .draggable = style {
            return true
        }
        return false
    }
}
