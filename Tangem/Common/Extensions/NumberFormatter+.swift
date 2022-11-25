//
//  NumberFormatter+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

extension NumberFormatter {
    /// Examples:
    /// `1000.34 -> 1 000,34`
    /// `1000000.34 -> 1 000 000,34`
    static let grouped: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.decimalSeparator = ","
        return formatter
    }()
}
