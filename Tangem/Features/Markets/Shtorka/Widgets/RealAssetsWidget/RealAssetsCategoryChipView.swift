//
//  RealAssetsCategoryChipView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct RealAssetsCategoryChipView: View {
    let title: String
    let style: Style
    let onTap: () -> Void
    var onClear: () -> Void = {}

    @Environment(\.isEnabled) private var isEnabled

    @ScaledMetric private var iconSize: CGFloat = 16
    @ScaledMetric private var height: CGFloat = 36

    var body: some View {
        HStack(spacing: 6) {
            SwiftUI.Button(action: onTap) {
                HStack(spacing: 4) {
                    Text(title)
                        .lineLimit(1)
                        .style(DesignSystem.Font.subheadingMediumToken, color: textColor)

                    if case .expandable = style {
                        icon(DesignSystem.Icons.ChevronDown.regular16)
                            .accessibilityHidden(true)
                    }
                }
                .padding(.leading, 12)
                .padding(.trailing, style.hasClearButton ? 0 : 10)
                .frame(height: height)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)

            if style.hasClearButton {
                SwiftUI.Button(action: onClear) {
                    icon(DesignSystem.Icons.Cross.regular16)
                        .padding(.trailing, 10)
                        .frame(height: height)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(Localization.commonReset))
            }
        }
        .background(backgroundColor, in: .capsule)
        .opacity(isEnabled ? 1 : Constants.disabledOpacity)
    }

    private func icon(_ imageType: ImageType) -> some View {
        imageType.image
            .renderingMode(.template)
            .resizable()
            .frame(size: .init(bothDimensions: iconSize))
            .foregroundStyle(textColor)
    }

    private var textColor: Color {
        switch style {
        case .expandable: DesignSystem.Color.textSecondary
        case .selected: DesignSystem.Color.textInversePrimary
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .expandable: DesignSystem.Color.bgOpaqueSecondary
        case .selected: DesignSystem.Color.bgInverse
        }
    }
}

extension RealAssetsCategoryChipView {
    enum Constants {
        static let disabledOpacity: CGFloat = 0.4
    }

    enum Style {
        case expandable
        case selected

        var hasClearButton: Bool {
            self == .selected
        }
    }
}

// MARK: - Previews

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        RealAssetsCategoryChipView(title: "All", style: .expandable, onTap: {}, onClear: {})
        RealAssetsCategoryChipView(title: "Commodities", style: .selected, onTap: {}, onClear: {})
        RealAssetsCategoryChipView(title: "Technology", style: .selected, onTap: {}, onClear: {})
    }
    .padding()
}
