//
//  FormattedFeeComponents.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct FormattedFeeComponents {
    let cryptoFee: String
    let fiatFee: String?
}

extension FormattedFeeComponents: Hashable {}
