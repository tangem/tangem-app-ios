//
//  IconViewSizeSettings.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

public enum IconViewSizeSettings {
    case tokenItem
    case tokenDetails
    case tokenDetailsToolbar
    case receive

    public var iconSize: CGSize {
        switch self {
        case .tokenItem: return .init(width: 40, height: 40)
        case .tokenDetails: return .init(bothDimensions: 48)
        case .tokenDetailsToolbar: return .init(bothDimensions: 24)
        case .receive: return .init(width: 80, height: 80)
        }
    }

    public var networkIconSize: CGSize {
        switch self {
        case .tokenItem: return .init(width: 16, height: 16)
        case .tokenDetails, .tokenDetailsToolbar: return .zero
        case .receive: return .init(width: 32, height: 32)
        }
    }

    public var networkIconBorderWidth: Double {
        switch self {
        case .tokenItem: return 2
        case .tokenDetails, .tokenDetailsToolbar: return 0
        case .receive: return 4
        }
    }

    public var networkIconOffset: CGSize {
        switch self {
        case .tokenItem: return .init(width: 4, height: -4)
        case .tokenDetails, .tokenDetailsToolbar: return .zero
        case .receive: return .init(width: 9, height: -9)
        }
    }
}
