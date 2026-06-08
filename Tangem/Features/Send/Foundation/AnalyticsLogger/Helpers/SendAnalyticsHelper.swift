//
//  SendAnalyticsHelper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum SendAnalyticsHelper {
    static func makeAnalyticsTokenName(from tokenItem: TokenItem) -> String {
        switch tokenItem.token?.metadata.kind {
        case .nonFungible:
            Analytics.ParameterValue.nft.rawValue
        case .fungible, .none:
            tokenItem.currencySymbol
        }
    }

    static func makeFeeTypeParameter(selectedFee: FeeOption?, supportFeeSelection: Bool) -> Analytics.ParameterValue {
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
