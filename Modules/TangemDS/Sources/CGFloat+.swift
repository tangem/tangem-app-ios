//
//  CGFloat+.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public extension CGFloat {
    static func unit(_ size: SizeUnit) -> CGFloat {
        size.value
    }
}
