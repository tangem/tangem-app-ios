//
//  WelcomeImportSheetItem.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct WelcomeImportSheetItem: Identifiable {
    let id: String
    var title: String
    var isEnabled: Bool
    var isLoading: Bool
    var action: () -> Void
}
