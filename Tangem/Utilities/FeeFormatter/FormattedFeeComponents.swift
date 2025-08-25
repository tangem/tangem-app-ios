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

    var formatted: String {
        var text = cryptoFee

        if let fiatFee = fiatFee {
            text += " \(AppConstants.dotSign) \(fiatFee)"
        }

        return text
    }
}

extension FormattedFeeComponents: Hashable {}
