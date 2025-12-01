//
//  CommonMarketsWidgetDataService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol MarketsWidgetsProvder {
    var widgetsPublisher: AnyPublisher<[MarketsWidgetModel], Never> { get }
    var widgets: [MarketsWidgetModel] { get }

    func initialize()
}

// MARK: - Common Implementation

final class CommonMarketsWidgetDataService {
    // MARK: - Private Properties

    private let _widgetsValueSubject: CurrentValueSubject<[MarketsWidgetModel], Never> = .init([])

    // MARK: - Private Implementation

    func isEnabled(for type: MarketsWidgetType) -> Bool {
        switch type {
        case .banner, .market, .pulse:
            return true
        case .news:
            return FeatureProvider.isAvailable(.marketsNews)
        case .earn:
            return FeatureProvider.isAvailable(.marketsEarn)
        }
    }

    func order(for type: MarketsWidgetType) -> Int {
        switch type {
        case .banner:
            return 0
        case .market:
            return 1
        case .news:
            return 2
        case .earn:
            return 3
        case .pulse:
            return 4
        }
    }
}

// MARK: - MarketsWidgetProvder

extension CommonMarketsWidgetDataService: MarketsWidgetsProvder {
    var widgetsPublisher: AnyPublisher<[MarketsWidgetModel], Never> {
        _widgetsValueSubject.eraseToAnyPublisher()
    }

    var widgets: [MarketsWidgetModel] {
        _widgetsValueSubject.value
    }

    func initialize() {
        let widgetTypes = MarketsWidgetType.allCases

        let widgetModels = widgetTypes.map {
            MarketsWidgetModel(
                type: $0,
                isEnabled: isEnabled(for: $0),
                order: order(for: $0)
            )
        }

        _widgetsValueSubject.send(widgetModels)
    }
}

// MARK: - Dependency injection

extension InjectedValues {
    var marketsWidgetsProvder: MarketsWidgetsProvder {
        get { Self[Key.self] }
        set { Self[Key.self] = newValue }
    }

    private struct Key: InjectionKey {
        static var currentValue: MarketsWidgetsProvder = CommonMarketsWidgetDataService()
    }
}
