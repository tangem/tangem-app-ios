//
//  MarketsMainWidgetErrorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct MarketsMainWidgetErrorView: View {
    let tryLoadAgain: () -> Void

    var body: some View {
        UnableToLoadDataView(
            isButtonBusy: false,
            retryButtonAction: tryLoadAgain
        )
        .frame(maxWidth: .infinity, maxHeight: Layout.defaultMaxHeight)
        .defaultRoundedBackground(verticalPadding: Layout.verticalPadding, horizontalPadding: Layout.horizontalPadding)
        .padding(.horizontal, Layout.defaultHorizontalInset)
    }
}

private extension MarketsMainWidgetErrorView {
    enum Layout {
        static let defaultHorizontalInset = 16.0
        static let verticalPadding: CGFloat = 34
        static let horizontalPadding: CGFloat = 10
        static let defaultMaxHeight: CGFloat = 130
    }
}
