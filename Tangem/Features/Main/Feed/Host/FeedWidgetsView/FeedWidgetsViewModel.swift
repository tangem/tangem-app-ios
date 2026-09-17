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
    private var widgets: [FeedWidget?] = []
    private var bag = Set<AnyCancellable>()

    init(providers: [FeedWidgetProvider]) {
        self.providers = providers

        bind()
    }

    func refresh() {
        providers.forEach { $0.refresh() }
    }

    func select(_ widget: FeedWidget) {
        guard let index = widgets.firstIndex(where: { $0?.id == widget.id }) else {
            return
        }

        providers[index].select()
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
