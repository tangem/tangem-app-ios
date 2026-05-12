//
//  SwapDisplayMode.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

enum SwapDisplayMode: String, CaseIterable, Identifiable {
    case simple
    case detailed

    var id: String { rawValue }

    var menuTitle: String {
        switch self {
        case .simple: return Localization.swapSimpleMode
        case .detailed: return Localization.swapDetailedMode
        }
    }
}
