//
//  EarnFilterType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemMacro

@CaseFlagable
enum EarnFilterType: String, CaseIterable, Encodable, CustomStringConvertible, Identifiable {
    case all
    case staking
    case yield

    var id: String {
        rawValue
    }

    var description: String {
        switch self {
        case .all: return Localization.commonAll
        case .staking: return Localization.commonStaking
        case .yield: return Localization.commonYieldMode
        }
    }

    var apiValue: EarnDTO.List.EarnType? {
        switch self {
        case .all: return nil
        case .staking: return .staking
        case .yield: return .yield
        }
    }

    /// String value for analytics (e.g. "[Earn] Best Opportunities Filter Type Applied").
    var analyticsTypeValue: String {
        switch self {
        case .all: return "All types"
        case .staking: return "Staking"
        case .yield: return "Yield"
        }
    }
}
