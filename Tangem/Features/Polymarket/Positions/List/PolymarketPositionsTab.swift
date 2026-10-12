//
//  PolymarketPositionsTab.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemUI

enum PolymarketPositionsTab: String, CaseIterable, TabNavigationItem {
    case active
    case finished

    var id: String { rawValue }

    var title: String {
        switch self {
        case .active: Localization.predictionPositionsActive
        case .finished: Localization.predictionPositionsFinished
        }
    }

    var emptyMessage: String {
        switch self {
        case .active: Localization.predictionPositionsEmptyActive
        case .finished: Localization.predictionPositionsEmptyFinished
        }
    }
}
