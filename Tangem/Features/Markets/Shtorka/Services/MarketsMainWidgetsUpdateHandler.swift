//
//  MarketsMainWidgetsUpdateHandler.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol MarketsMainWidgetsUpdateHandler {
    var widgetsUpdateStateEventPublisher: AnyPublisher<WidgetLoadingStateEvent, Never> { get }

    func performUpdateLoading(state: WidgetLoadingState, for widgetType: MarketsWidgetType)
}
