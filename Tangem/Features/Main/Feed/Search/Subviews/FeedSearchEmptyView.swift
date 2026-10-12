//
//  FeedSearchEmptyView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct FeedSearchEmptyView: View {
    let title: String

    var body: some View {
        Text(title)
            .multilineTextAlignment(.center)
            .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, Constants.horizontalPadding)
            .padding(.top, Constants.topPadding)
    }
}

// MARK: - Constants

private extension FeedSearchEmptyView {
    enum Constants {
        static let horizontalPadding: CGFloat = 16
        static let topPadding: CGFloat = 40
    }
}
