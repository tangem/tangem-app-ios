//
//  AddressBooksSearchNoResultsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct AddressBooksSearchNoResultsView: View {
    @ScaledMetric private var iconContainerSize: CGFloat = 48
    @ScaledMetric private var iconSize: CGFloat = 24

    var body: some View {
        VStack(spacing: 12) {
            icon

            Text(Localization.addressBookSearchNoResults)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 16)
    }

    private var icon: some View {
        DesignSystem.Color.bgSecondary
            .frame(width: iconContainerSize, height: iconContainerSize)
            .overlay {
                DesignSystem.Icons.Search.regular24.image
                    .resizable()
                    .renderingMode(.template)
                    .frame(width: iconSize, height: iconSize)
                    .foregroundColor(DesignSystem.Color.iconSecondary)
            }
            .clipShape(Circle())
    }
}

// MARK: - Previews

#Preview {
    AddressBooksSearchNoResultsView()
        .background(DesignSystem.Color.bgBase.edgesIgnoringSafeArea(.all))
}
