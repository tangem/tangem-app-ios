//
//  Int+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension Int: @retroactive Identifiable {
    public var id: Int { self }
}
