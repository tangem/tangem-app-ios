//
//  TokenListLoadingPlaceholderView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct TokenListLoadingPlaceholderView: View {
    let iconDimension: CGFloat

    var body: some View {
        VStack(spacing: 0.0) {
            TokenListSectionLoadingPlaceholderView()

            TokenListItemLoadingPlaceholderView(
                iconDimension: iconDimension,
                hasTokenPlaceholder: false
            )

            TokenListItemLoadingPlaceholderView(
                iconDimension: iconDimension,
                hasTokenPlaceholder: true
            )
        }
    }
}

// MARK: - Previews

struct TokenListLoadingPlaceholderView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Colors.Background
                .secondary
                .ignoresSafeArea()

            TokenListLoadingPlaceholderView(iconDimension: 40.0)
                .cornerRadiusContinuous(14.0)
                .padding()
                .infinityFrame(alignment: .top)
        }
    }
}
