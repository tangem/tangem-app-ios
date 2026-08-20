//
//  WelcomeV2ImportSheetItem.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct WelcomeV2ImportSheetItem: Identifiable {
    let id: String
    let title: String
    let action: () -> Void
}
