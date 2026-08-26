//
//  TangemPayActivateCardArtView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import Kingfisher
import TangemAssets

/// The card is deliberately larger than the screen and anchored past its top-left corner, so only the
/// number end of it shows. Every offset below is measured from that corner in the 402pt design frame.
struct TangemPayActivateCardArtView: View {
    let imageURL: URL?
    let digits: String

    var body: some View {
        panel
            // Not an alignment: SwiftUI re-centres a child wider than its parent, which the panel always is.
            .position(
                x: Constants.panelOrigin.x + Constants.panelWidth / 2,
                y: Constants.panelOrigin.y + Constants.panelHeight / 2
            )
            .frame(maxWidth: .infinity)
            .frame(height: Constants.visibleHeight)
            .clipped()
    }

    private var panel: some View {
        artwork
            .frame(width: Constants.panelWidth, height: Constants.panelHeight)
            .overlay(alignment: .topLeading) { digitGroups }
            .clipShape(panelShape)
            .overlay {
                panelShape
                    .strokeBorder(Color.white.opacity(Constants.borderOpacity), lineWidth: Constants.borderWidth)
            }
    }

    private var artwork: some View {
        KFImage(imageURL)
            .placeholder {
                Assets.Visa.cardActivation.image
                    .resizable()
            }
            .resizable()
    }

    private var panelShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Constants.cornerRadius, style: .continuous)
    }

    private var digitGroups: some View {
        HStack(spacing: Constants.groupSpacing) {
            ForEach(0 ..< Constants.placeholderGroupCount, id: \.self) { _ in
                Text(Constants.placeholderGroup)
                    .opacity(Constants.placeholderGroupOpacity)
            }

            Text(editableGroup)
        }
        .style(DesignSystem.Font.displayMediumToken, color: DesignSystem.Color.textStaticDarkTertiary)
        .monospacedDigit()
        .lineLimit(1)
        .frame(width: Constants.panelWidth - Constants.digitsTrailingInset, alignment: .trailing)
        .offset(y: Constants.digitsTop)
    }

    private var editableGroup: AttributedString {
        let typed = Array(digits)

        return (0 ..< Constants.groupLength).reduce(into: AttributedString()) { result, index in
            let digit = typed[safe: index]
            var slot = AttributedString(digit.map(String.init) ?? Constants.placeholderDigit)
            slot.foregroundColor = digit == nil
                ? DesignSystem.Color.textStaticDarkTertiary
                : DesignSystem.Color.textStaticDarkPrimary
            result.append(slot)
        }
    }
}

private extension TangemPayActivateCardArtView {
    enum Constants {
        static let panelWidth: CGFloat = 566
        static let panelHeight: CGFloat = 364
        static let panelOrigin = CGPoint(x: -277, y: -34)
        static let visibleHeight = panelOrigin.y + panelHeight
        static let cornerRadius: CGFloat = 32
        static let borderOpacity: Double = 0.1
        static let borderWidth: CGFloat = 1

        static let digitsTop: CGFloat = 283.24
        static let digitsTrailingInset: CGFloat = 31.23
        static let groupSpacing: CGFloat = 16
        static let groupLength = 4
        static let placeholderGroupCount = 3
        static let placeholderGroup = "0000"
        static let placeholderDigit = "0"
        static let placeholderGroupOpacity: Double = 0.4
    }
}
