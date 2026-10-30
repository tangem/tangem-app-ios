//
//  TokenListSectionLoadingPlaceholderView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct TokenListSectionLoadingPlaceholderView: View {
    var body: some View {
        ZStack {
            HStack {
                Shimmer().variant(.custom(width: 90.0, height: 18.0, cornerRadius: 3))

                Spacer()
            }
            .padding(.horizontal, 14.0)
            .padding(.vertical, 12.0)
        }
        .background(Colors.Background.primary)
    }
}

// MARK: - Previews

#Preview {
    ZStack {
        Colors.Background
            .secondary
            .ignoresSafeArea()

        VStack {
            TokenListSectionLoadingPlaceholderView()

            TokenListSectionLoadingPlaceholderView()
        }
        .infinityFrame(alignment: .top)
    }
}
