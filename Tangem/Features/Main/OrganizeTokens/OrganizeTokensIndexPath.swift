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
    let item: Int
}

// MARK: - CustomStringConvertible protocol conformance

extension OrganizeTokensIndexPath: CustomStringConvertible {
    var description: String {
        "<OrganizeTokensIndexPath; [\(outerSection), \(innerSection), \(item)]>"
    }
}
