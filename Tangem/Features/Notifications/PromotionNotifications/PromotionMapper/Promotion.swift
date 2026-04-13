//
//  Promotion.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct Promotion: Hashable {
    let id: Int
    let placeholder: PromotionPlacement
    let priority: String?
    let title: String
    let subtitle: String
    let iconUrl: URL
    let deeplink: URL?
    let buttonEnabled: Bool
    let buttonText: String?
    let dismissable: Bool
}
