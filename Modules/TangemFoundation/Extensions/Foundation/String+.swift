//
//  String+.swift
//  TangemFoundation
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public extension String {
    func trim(toLength length: Int) -> String {
        String(prefix(length))
    }
}
