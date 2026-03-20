//
//  NotificationBannerKind.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Proxy-entity that needs to force map
/// into new DesignSystem BannerType
/// if a specific new type is documented
enum NotificationBannerKind {
    case status
    case critical
    case warning
    case informational
    case promo(Effect)
    case survey

    enum Effect {
        case card
        case magic
    }
}
