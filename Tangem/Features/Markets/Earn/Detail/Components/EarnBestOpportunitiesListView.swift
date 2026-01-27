//
//  EarnBestOpportunitiesListView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct EarnBestOpportunitiesListView: View {
    var body: some View {
        VStack(spacing: .zero) {
            // Placeholder for future list implementation
            // Will use LazyVStack with EarnTokenItemView
            Color.clear
                .frame(height: Layout.placeholderHeight)
        }
        .padding(.horizontal, Layout.horizontalPadding)
    }
}

private extension EarnBestOpportunitiesListView {
    enum Layout {
        static let placeholderHeight: CGFloat = 200.0
        static let horizontalPadding: CGFloat = 16.0
    }
}
