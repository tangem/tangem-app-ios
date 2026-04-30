//
//  FeeAnalyticsParameterBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct FeeAnalyticsParameterBuilder {
    private let supportFeeSelection: Bool

    init(supportFeeSelection: Bool) {
        self.supportFeeSelection = supportFeeSelection
    }

    func analyticsParameter(selectedFee: FeeOption?) -> Analytics.ParameterValue {
        if !supportFeeSelection {
            return .fixed
        }

        guard let selectedFee else {
            assertionFailure("selectedFeeTypeAnalyticsParameter not found")
            return .null
        }

        return selectedFee.analyticsValue
    }
}
