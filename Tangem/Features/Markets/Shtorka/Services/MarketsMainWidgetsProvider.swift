//
//  MarketsMainWidgetsProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol MarketsMainWidgetsProvider {
    var widgetsPublisher: AnyPublisher<[MarketsWidgetModel], Never> { get }
    var widgets: [MarketsWidgetModel] { get }

    func reloadWidgets()
}
