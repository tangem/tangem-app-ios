//
//  TokenPriceFormatter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol TokenPriceFormatter {
    func formatFiatBalance(_ value: Decimal?) -> String
}
