//
//  PolymarketPositionsViewAllSection.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct PolymarketPositionsViewAllSection<Content: View>: View {
    let showsViewAll: Bool
    let onViewAll: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: Constants.spacing) {
            content()

            if showsViewAll {
                PolymarketPositionsViewAllButton(action: onViewAll)
            }
        }
    }
}

// MARK: - Constants

private enum Constants {
    static let spacing: CGFloat = 8
}
