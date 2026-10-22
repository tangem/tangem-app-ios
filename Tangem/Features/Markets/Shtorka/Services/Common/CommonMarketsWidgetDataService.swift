//
//  CommonMarketsWidgetDataService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

// MARK: - Common Implementation

final class CommonMarketsMainWidgetDataService {
    // MARK: - Private Properties

    private let _widgetsUpdateStateEventSubject: PassthroughSubject<WidgetLoadingStateEvent, Never> = .init()

    /// Tracks whether the initial load has completed (all widgets finished loading at least once)
    private var hasCompletedInitialLoad: Bool = false

    private var widgetsLoadingStates: [MarketsWidgetType: WidgetLoadingState]

    // MARK: - Init

    init(widgetTypes: Set<MarketsWidgetType>) {
        widgetsLoadingStates = widgetTypes.reduce(into: [:]) { partialResult, widgetType in
            partialResult[widgetType] = .loading
        }
    }
}

// MARK: - MarketsMainWidgetsUpdateHelper

extension CommonMarketsMainWidgetDataService: MarketsMainWidgetsUpdateHandler {
    var widgetsUpdateStateEventPublisher: AnyPublisher<WidgetLoadingStateEvent, Never> {
        _widgetsUpdateStateEventSubject.eraseToAnyPublisher()
    }

    func performUpdateLoading(state: WidgetLoadingState, for widgetType: MarketsWidgetType) {
        widgetsLoadingStates[widgetType] = state

        let allFinishedLoading = widgetsLoadingStates.values.allSatisfy { !$0.isLoading }
        let allFailed = widgetsLoadingStates.allSatisfy { $0.value.isError }

        // All widgets failed with errors
        if allFailed {
            hasCompletedInitialLoad = true
            AppLogger.tag("MarketsWidgets").debug("All widgets failed - sending .allFailed")
            _widgetsUpdateStateEventSubject.send(.allFailed)
            return
        }

        // All widgets finished loading (some may have errors, some succeeded)
        if allFinishedLoading {
            hasCompletedInitialLoad = true
            AppLogger.tag("MarketsWidgets").debug("All widgets finished loading - sending .loaded")
            _widgetsUpdateStateEventSubject.send(.loaded)
            return
        }

        // Some widgets are still loading
        if hasCompletedInitialLoad {
            // After initial load - this is a reload (e.g., retry after error)
            let reloadingWidgets = widgetsLoadingStates
                .filter { $0.value.isLoading }
                .map(\.key)
            AppLogger.tag("MarketsWidgets").debug("Reloading widgets: \(reloadingWidgets.map(\.rawValue)) - sending .reloading")
            _widgetsUpdateStateEventSubject.send(.reloading(reloadingWidgets))
        } else {
            _widgetsUpdateStateEventSubject.send(.initialLoading)
        }
    }
}
