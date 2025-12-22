//
//  OrganizeTokensIndexPath.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct OrganizeTokensIndexPath: Hashable {
    let outerSection: Int
    let innerSection: Int
    // [REDACTED_TODO_COMMENT]
    let _item: Int

    // [REDACTED_TODO_COMMENT]
    init(outerSection: Int, innerSection: Int, item: Int) {
        self.outerSection = outerSection
        self.innerSection = innerSection
        _item = item
    }
}
