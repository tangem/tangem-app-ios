//
//  FeeOption.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum FeeOption: String, Hashable {
    case slow
    case market
    case fast
    case custom

    var icon: ImageType {
        switch self {
        case .slow:
            return Assets.slowFeeIcon
        case .market:
            return Assets.marketFeeIcon
        case .fast:
            return Assets.fastFeeIcon
        case .custom:
            return Assets.customFeeIcon
        }
    }

    var title: String {
        switch self {
        case .slow:
            return Localization.commonFeeSelectorOptionSlow
        case .market:
            return Localization.commonFeeSelectorOptionMarket
        case .fast:
            return Localization.commonFeeSelectorOptionFast
        case .custom:
            return Localization.commonFeeSelectorOptionCustom
        }
    }
}
