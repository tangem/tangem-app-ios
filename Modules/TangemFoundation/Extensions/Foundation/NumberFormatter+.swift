//
//  NumberFormatter+.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public extension NumberFormatter {
    func format(number: Decimal) -> String {
        string(from: number as NSDecimalNumber) ?? number.description
    }
}
