//
//  NewsQuickRecapView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemFoundation
import TangemLocalization
import TangemUI

struct NewsQuickRecapView: View {
    let content: String

    var body: some View {
        if FeatureProvider.isAvailable(.redesign) {
            redesignContent
        } else {
            legacyContent
        }
    }

    // MARK: - Redesign

    private var redesignContent: some View {
        VStack(alignment: .leading, spacing: .zero) {
            redesignTitle
                .padding(.top, .unit(.x2))

            FixedSpacer(height: Constants.titleBottomSpacing)

            redesignBody
        }
    }

    private var redesignTitle: some View {
        Text("✦ \(Localization.newsQuickRecap)")
            .style(.Tangem.Subheadline.medium, color: .clear)
            .overlay(
                LinearGradient(
                    colors: Constants.titleGradientColors,
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .mask(
                    Text("✦ \(Localization.newsQuickRecap)")
                        .style(.Tangem.Subheadline.medium, color: .black)
                )
            )
    }

    private var redesignBody: some View {
        HStack(alignment: .top, spacing: .zero) {
            Rectangle()
                .fill(Constants.leadingLineColor)
                .frame(width: 1)

            Text(content)
                .style(.Tangem.Body16.regular, color: .Tangem.Text.Neutral.primary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, .unit(.x3))
        }
        .padding(.leading, .unit(.x2))
    }

    // MARK: - Legacy

    private var legacyContent: some View {
        HStack(alignment: .top, spacing: 0) {
            Separator(height: .exact(2), color: Color.Tangem.Border.Neutral.primary, axis: .vertical)

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Assets.Glyphs.quickRecap.image
                        .foregroundStyle(Color.Tangem.Fill.Status.accent)

                    Text(Localization.newsQuickRecap)
                        .style(Fonts.Bold.footnote, color: Color.Tangem.Text.Status.accent)
                }

                Text(content)
                    .style(Fonts.Regular.body, color: Color.Tangem.Text.Neutral.primary)
            }
            .padding(.leading, 16)
            .padding(.bottom, 8)
        }
    }
}

private extension NewsQuickRecapView {
    enum Constants {
        static let titleBottomSpacing: CGFloat = .unit(.x2) + .unit(.half)
        static let titleGradientColors = [
            Color(red: 163 / 255, green: 160 / 255, blue: 255 / 255),
            Color(red: 247 / 255, green: 157 / 255, blue: 255 / 255),
        ]
        static let leadingLineColor = Color(red: 169 / 255, green: 159 / 255, blue: 255 / 255)
    }
}
