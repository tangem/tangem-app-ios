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
