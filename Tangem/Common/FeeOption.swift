//
//  FeeOption.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemAssets
import TangemAccessibilityIdentifiers
import TangemMacro

@CaseFlagable
enum FeeOption: Hashable, Equatable, Comparable {
    case suggestedByDApp(dappName: String)
    case slow
    case market
    case fast
    case custom

    var icon: ImageType {
        switch self {
        case .suggestedByDApp:
            return Assets.FeeOptions.suggestedFeeIcon
        case .slow:
            return Assets.FeeOptions.slowFeeIcon
        case .market:
            return Assets.FeeOptions.marketFeeIcon
        case .fast:
            return Assets.FeeOptions.fastFeeIcon
        case .custom:
            return Assets.FeeOptions.customFeeIcon
        }
    }

    var title: String {
        switch self {
        case .suggestedByDApp(let dappName):
            return Localization.wcFeeSuggested(dappName)
        case .slow:
            return Localization.commonFeeSelectorOptionSlow
        case .market:
            return Localization.commonFeeSelectorOptionMarket
        case .fast:
            return Localization.commonFeeSelectorOptionFast
        case .custom:
            return Localization.commonCustom
        }
    }

    var analyticsValue: Analytics.ParameterValue {
        switch self {
        case .suggestedByDApp:
            return .custom
        case .slow:
            return .transactionFeeMin
        case .market:
            return .transactionFeeNormal
        case .fast:
            return .transactionFeeMax
        case .custom:
            return .custom
        }
    }

    var accessibilityIdentifier: String {
        switch self {
        case .suggestedByDApp:
            return FeeAccessibilityIdentifiers.suggestedFeeOption
        case .slow:
            return FeeAccessibilityIdentifiers.slowFeeOption
        case .market:
            return FeeAccessibilityIdentifiers.marketFeeOption
        case .fast:
            return FeeAccessibilityIdentifiers.fastFeeOption
        case .custom:
            return FeeAccessibilityIdentifiers.customFeeOption
        }
    }
}
