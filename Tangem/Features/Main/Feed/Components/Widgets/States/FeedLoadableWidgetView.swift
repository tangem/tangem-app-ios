//
//  FeedLoadableWidgetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemFoundation

struct FeedLoadableWidgetView<Value, Content: View>: View {
    let state: LoadingResult<Value, FeedWidget.LoadError>
    @ViewBuilder let content: (Value) -> Content

    var body: some View {
        switch state {
        case .loading:
            FeedWidgetSkeletonView()

        case .failure:
            FeedWidgetLoadErrorView()

        case .success(let value):
            content(value)
        }
    }
}
