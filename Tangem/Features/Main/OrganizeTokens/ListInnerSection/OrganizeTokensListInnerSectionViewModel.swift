//
//  OrganizeTokensListInnerSectionViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct OrganizeTokensListInnerSectionViewModel: Hashable, Identifiable {
    enum SectionStyle: Hashable {
        case invisible
        case fixed(title: String)
        case draggable(title: String)
    }

    let id: AnyHashable
    let style: SectionStyle
}

// MARK: - CustomStringConvertible protocol conformance

extension OrganizeTokensListInnerSectionViewModel.SectionStyle: CustomStringConvertible {
    var description: String {
        switch self {
        case .invisible:
            return "Invisible"
        case .fixed(title: let title):
            return "Fixed(\(title))"
        case .draggable(title: let title):
            return "Draggable(\(title))"
        }
    }
}
