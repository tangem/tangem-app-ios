//
//  FeedEarnWidgetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemFoundation

struct FeedEarnWidgetView: View {
    let state: LoadingResult<FeedEarnWidgetState, FeedWidget.LoadError>

    var body: some View {
        FeedLoadableWidgetView(state: state) { earn in
            FeedProductCardView(caption: earn.caption, message: earn.message, appearance: .earn)
        }
    }
}
