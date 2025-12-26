//
//  MarketsListErrorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct MarketsListErrorView: View {
    let tryLoadAgain: () -> Void

    var body: some View {
        UnableToLoadDataView(
            isButtonBusy: false,
            retryButtonAction: tryLoadAgain
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
