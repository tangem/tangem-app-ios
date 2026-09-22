//
//  FeedTabPage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import CoreGraphics

struct FeedTabPage: Identifiable {
    let tab: FeedTab
    var topInset: CGFloat = 0
    var offset: CGFloat = 0

    var id: String { tab.id }
}
