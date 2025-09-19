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
        case .fungible, .yield, .none:
            tokenItem.currencySymbol
        }
    }
}
