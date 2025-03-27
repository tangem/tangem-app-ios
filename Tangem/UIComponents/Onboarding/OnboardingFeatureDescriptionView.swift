//
//  OnboardingFeatureDescriptionView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct OnboardingFeatureDescriptionView: View {
    let iconImage: Image
    var title: String? = nil
    let description: String

    private let iconSize: Double = 42

    @Environment(\.colorScheme) private var colorScheme

    private var iconBackgroundColor: Color {
        return colorScheme == .light ? Colors.Background.secondary : Colors.Text.disabled
    }

    var body: some View {
        HStack(spacing: 16) {
            iconBackgroundColor
                .frame(width: iconSize, height: iconSize)
                .cornerRadius(iconSize / 2)
                .overlay(
                    iconImage
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(Colors.Text.primary1)
                        .padding(.all, 11)
                )

            VStack(alignment: .leading, spacing: 3) {
                if let title {
                    Text(title)
                        .style(Fonts.Bold.callout, color: Colors.Text.primary1)
                }

                Text(description)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
    }
}
