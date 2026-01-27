//
//  CommonMarketsWidgetDataService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

typealias MarketsWidgetDataService = MarketsMainWidgetsProvider & MarketsMainWidgetsUpdateHandler

// MARK: - Common Implementation

final class CommonMarketsMainWidgetDataService {
    // MARK: - Private Properties

    private let _widgetsValueSubject: CurrentValueSubject<[MarketsWidgetModel], Never> = .init([])
    private let _widgetsUpdateStateEventSubject: PassthroughSubject<WidgetLoadingStateEvent, Never> = .init()

    /// Tracks whether the initial load has completed (all widgets finished loading at least once)
    private var hasCompletedInitialLoad: Bool = false

    private lazy var widgetsLoadingStates: [MarketsWidgetType: WidgetLoadingState] = {
        let allCases = MarketsWidgetType.allCases
        let enabledCases = allCases.filter { isEnabled(for: $0) }

        return enabledCases.reduce(into: [:]) { partialResult, widgetType in
            partialResult[widgetType] = .loading
        }
    }()

    // MARK: - Private Implementation

    func isEnabled(for type: MarketsWidgetType) -> Bool {
        switch type {
        case .market, .pulse, .news:
            return true
        case .earn:
            return FeatureProvider.isAvailable(.marketsEarn)
        }
    }

    func order(for type: MarketsWidgetType) -> Int {
        switch type {
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

extension CommonMarketsMainWidgetDataService: MarketsMainWidgetsProvider {
    var widgetsPublisher: AnyPublisher<[MarketsWidgetModel], Never> {
        _widgetsValueSubject.eraseToAnyPublisher()
    }

    var widgetsUpdateStateEventPublisher: AnyPublisher<WidgetLoadingStateEvent, Never> {
        _widgetsUpdateStateEventSubject.eraseToAnyPublisher()
    }

    var widgets: [MarketsWidgetModel] {
        _widgetsValueSubject.value
    }

    func reloadWidgets() {
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

// MARK: - MarketsMainWidgetsUpdateHelper

extension CommonMarketsMainWidgetDataService: MarketsMainWidgetsUpdateHandler {
    func performUpdateLoading(state: WidgetLoadingState, for widgetType: MarketsWidgetType) {
        AppLogger.debug("[MarketsWidgets] Widget \(widgetType.rawValue) state changed to: \(state)")

        widgetsLoadingStates[widgetType] = state

        let allFinishedLoading = widgetsLoadingStates.values.allSatisfy { !$0.isLoading }
        let allFailed = widgetsLoadingStates.allSatisfy { $0.value.isError }

        AppLogger.debug("[MarketsWidgets] Loading states: \(widgetsLoadingStates.map { "\($0.key.rawValue): \($0.value)" })")

        // All widgets failed with errors
        if allFailed {
            hasCompletedInitialLoad = true
            AppLogger.debug("[MarketsWidgets] All widgets failed - sending .allFailed")
            _widgetsUpdateStateEventSubject.send(.allFailed)
            return
        }

        // All widgets finished loading (some may have errors, some succeeded)
        if allFinishedLoading {
            hasCompletedInitialLoad = true
            AppLogger.debug("[MarketsWidgets] All widgets finished loading - sending .loaded")
            _widgetsUpdateStateEventSubject.send(.loaded)
            return
        }

        // Some widgets are still loading
        if hasCompletedInitialLoad {
            // After initial load - this is a reload (e.g., retry after error)
            let reloadingWidgets = widgetsLoadingStates
                .filter { $0.value.isLoading }
                .map(\.key)
            AppLogger.debug("[MarketsWidgets] Reloading widgets: \(reloadingWidgets.map(\.rawValue)) - sending .reloading")
            _widgetsUpdateStateEventSubject.send(.reloading(reloadingWidgets))
        } else {
            // First time loading
            AppLogger.debug("[MarketsWidgets] Initial loading in progress - sending .initialLoading")
            _widgetsUpdateStateEventSubject.send(.initialLoading)
        }
    }
}

// MARK: - Dependency injection

extension InjectedValues {
    var marketsWidgetsProvider: MarketsMainWidgetsProvider {
        service
    }

    var marketsWidgetsUpdateHandler: MarketsMainWidgetsUpdateHandler {
        service
    }

    private var service: MarketsWidgetDataService {
        get { Self[Key.self] }
        set { Self[Key.self] = newValue }
    }

    private struct Key: InjectionKey {
        static var currentValue: MarketsWidgetDataService = CommonMarketsMainWidgetDataService()
    }
}
