//
//  FeedProductCardLayout.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils

struct FeedProductCardLayout<Header: View, Content: View, Background: View>: View {
    @ViewBuilder let header: () -> Header
    @ViewBuilder let content: () -> Content
    @ViewBuilder let background: () -> Background

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.spacing) {
            header()

            Spacer(minLength: 0)

            content()
        }
        .padding(Constants.padding)
        .infinityFrame(alignment: .leading)
        .background {
            background()
                .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius, style: .continuous))
        }
    }
}

// MARK: - Constants

private enum Constants {
    static let padding: CGFloat = 16
    static let spacing: CGFloat = 8
    static let cornerRadius: CGFloat = 24
}
