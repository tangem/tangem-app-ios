//
//  FeeAnalyticsParameterBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct FeeAnalyticsParameterBuilder {
    private let isFixedFee: Bool

    init(isFixedFee: Bool) {
        self.isFixedFee = isFixedFee
    }

    func analyticsParameter(selectedFee: FeeOption?) -> Analytics.ParameterValue {
        if isFixedFee {
            return .fixed
        }

        guard let selectedFee else {
            assertionFailure("selectedFeeTypeAnalyticsParameter not found")
            return .null
        }

        return selectedFee.analyticsValue
    }
}
