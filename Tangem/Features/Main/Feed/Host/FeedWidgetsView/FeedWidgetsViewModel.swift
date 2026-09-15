//
//  FeedWidgetsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

final class FeedWidgetsViewModel: ObservableObject {
    let columns: [FeedWidgetColumn]

    var stretchesProductCard: Bool {
        columns.filter(\.isProductCard).count == 1
    }

    init(widgets: [FeedWidget]) {
        columns = FeedWidgetColumn.columns(packing: widgets)
    }
}
