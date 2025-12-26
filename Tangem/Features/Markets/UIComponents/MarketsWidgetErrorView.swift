//
//  MarketsWidgetErrorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct MarketsWidgetErrorView: View {
    let tryLoadAgain: () -> Void

    var body: some View {
        UnableToLoadDataView(
            isButtonBusy: false,
            retryButtonAction: tryLoadAgain
        )
        .infinityFrame(axis: .horizontal, alignment: .center)
        .defaultRoundedBackground(verticalPadding: Layout.verticalPadding, horizontalPadding: Layout.horizontalPadding)
        .padding(.horizontal, Layout.defaultHorizontalInset)
    }
}

private extension MarketsWidgetErrorView {
    enum Layout {
        static let defaultHorizontalInset = 16.0
        static let verticalPadding: CGFloat = 34
        static let horizontalPadding: CGFloat = 10
        static let defaultMaxHeight: CGFloat = 130
    }
}
