//
//  WidgetLoadingStateEvent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct WidgetLoadingStateEvent: Identifiable, Hashable {
    let type: MarketsWidgetType
    let state: WidgetLoadingState

    var id: MarketsWidgetType.ID {
        type.id
    }
}
