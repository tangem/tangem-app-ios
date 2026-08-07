//
//  TokenListLoadingPlaceholderView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct TokenListLoadingPlaceholderView: View {
    var body: some View {
        VStack(spacing: 0.0) {
            TokenListSectionLoadingPlaceholderView()

            TokenListItemLoadingPlaceholderView(
                style: .tokenList(hasNetworkItemPlaceholder: false)
            )

            TokenListItemLoadingPlaceholderView(
                style: .tokenList(hasNetworkItemPlaceholder: true)
            )
        }
    }
}

// MARK: - Previews

#Preview {
    ZStack {
        Colors.Background
            .secondary
            .ignoresSafeArea()

        TokenListLoadingPlaceholderView()
            .cornerRadiusContinuous(14.0)
            .padding()
            .infinityFrame(alignment: .top)
    }
}
