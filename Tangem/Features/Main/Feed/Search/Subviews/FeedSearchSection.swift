//
//  FeedSearchSection.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct FeedSearchSection<Content: View>: View {
    private let title: String
    private let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.headerSpacing) {
            Text(title)
                .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)
                .padding(.horizontal, Constants.horizontalPadding)

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Constants

private enum Constants {
    static let headerSpacing: CGFloat = 16
    static let horizontalPadding: CGFloat = 16
}
