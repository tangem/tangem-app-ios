//
//  MarketsMainWidgetsUpdateHandler.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol MarketsMainWidgetsUpdateHandler {
    func performUpdateLoading(state: WidgetLoadingState, for widgetType: MarketsWidgetType)
}
