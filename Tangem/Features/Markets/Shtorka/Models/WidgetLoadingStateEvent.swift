//
//  WidgetLoadingStateEvent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum WidgetLoadingStateEvent: String, Identifiable, Hashable {
    case readyForDisplay = "ready_for_display"
    case lockedForDisplay = "locked_for_display"
    case allWidgetsWithError = "all_widgets_with_error"

    var id: String {
        rawValue
    }
}
