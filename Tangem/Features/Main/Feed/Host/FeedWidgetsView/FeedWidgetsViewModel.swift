//
//  FeedWidgetsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import CombineExt
import TangemFoundation

final class FeedWidgetsViewModel: ObservableObject {
    @Published private(set) var columns: [FeedWidgetColumn] = []

    var stretchesProductCard: Bool {
        columns.filter(\.isProductCard).count == 1
    }

    private let providers: [FeedWidgetProvider]
    private let analytics: FeedWidgetsAnalytics
    private var widgets: [FeedWidget?] = []
    private var bag = Set<AnyCancellable>()

    init(providers: [FeedWidgetProvider], analytics: FeedWidgetsAnalytics) {
        self.providers = providers
        self.analytics = analytics

        bind()
    }

    func refresh() {
        providers.forEach { $0.refresh() }
    }

    func select(_ widget: FeedWidget) {
        guard let index = widgets.firstIndex(where: { $0?.id == widget.id }),
              let currentWidget = widgets[index] else {
            return
        }

        switch currentWidget.loadingState {
        case .loading:
            return

        case .failure:
            providers[index].refresh()

        case .success:
            analytics.logSelection(of: currentWidget)
            providers[index].select()
        }
    }

    func updateVisibility(of widget: FeedWidget, isVisible: Bool) {
        analytics.updateVisibility(of: widget, isVisible: isVisible)
    }

    func updateContentVisibility(_ isVisible: Bool) {
        analytics.updateContentVisibility(isVisible)
    }
}

// MARK: - Private

private extension FeedWidgetsViewModel {
    func bind() {
        providers
            .map(\.widgetPublisher)
            .combineLatest()
            .removeDuplicates()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, widgets in
                viewModel.widgets = widgets
                viewModel.columns = FeedWidgetColumn.columns(packing: widgets.compactMap { $0 })
            }
            .store(in: &bag)
    }
}
