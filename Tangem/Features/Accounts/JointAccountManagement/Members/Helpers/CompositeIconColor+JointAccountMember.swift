//
//  CompositeIconColor+JointAccountMember.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

extension CompositeIconColor {
    static func jointAccountMember(at index: Int) -> CompositeIconColor {
        allCases[index % allCases.count]
    }
}
