//
//  ModalStatus.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

public struct ModalStatus<Asset: View, ExtraBottom: View, Details: View>: View, Setupable {
    let appearance: ModalStatusAppearance?
    let title: String
    let description: String?
    let assetContent: Asset
    let extraBottomContent: ExtraBottom
    let detailsContent: Details

    var titleStyle: ModalStatusTitleStyle = .status
    var actions: ModalStatusActions?

    init(
        appearance: ModalStatusAppearance?,
        title: String,
        description: String?,
        assetSlot: Asset,
        extraBottom: ExtraBottom,
        details: Details
    ) {
        self.appearance = appearance
        self.title = title
        self.description = description
        assetContent = assetSlot
        extraBottomContent = extraBottom
        detailsContent = details
    }

    public var body: some View {
        content.ifLet(actions) { content, actions in
            content.footer {
                Footer(.buttons(
                    primary: actions.primary.styleType(.primary),
                    secondary: actions.secondary?.styleType(.secondary(.default))
                ))
            }
        }
    }
}

// MARK: - Content

private extension ModalStatus {
    // MARK: - View properties

    var content: some View {
        VStack(spacing: Metrics.itemSpacing) {
            header

            detailsContent
        }
        .padding(Metrics.padding)
        .frame(maxWidth: .infinity)
    }

    var header: some View {
        VStack(spacing: Metrics.itemSpacing) {
            asset

            texts

            extraBottomContent
        }
        .padding(.bottom, Metrics.headerBottomPadding)
    }

    @ViewBuilder
    var asset: some View {
        if let appearance {
            Avatar(.icon(appearance.glyph, appearance: appearance.avatarAppearance), size: .size72)
        } else {
            assetContent
        }
    }

    var texts: some View {
        VStack(spacing: Metrics.textsSpacing) {
            Text(title)
                .style(titleStyle.font, color: DesignSystem.Color.textPrimary)

            if let description {
                Text(description)
                    .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
            }
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, Metrics.textsHorizontalPadding)
    }
}

// MARK: - Metrics

private enum Metrics {
    static let padding: CGFloat = 16
    static let itemSpacing: CGFloat = 16
    static let headerBottomPadding: CGFloat = 24
    static let textsSpacing: CGFloat = 8
    static let textsHorizontalPadding: CGFloat = 16
}
