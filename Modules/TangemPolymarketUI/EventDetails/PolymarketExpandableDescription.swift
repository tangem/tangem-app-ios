//
//  PolymarketExpandableDescription.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

public struct PolymarketExpandableDescription: View {
    private let text: String
    private let isExpanded: Bool
    private let onReadMore: () -> Void

    @State private var collapsedHeight: CGFloat = 0
    @State private var fullHeight: CGFloat = 0

    private var isTruncated: Bool {
        fullHeight > collapsedHeight + Constants.heightComparisonTolerance
    }

    private var showsReadMore: Bool {
        !isExpanded && isTruncated
    }

    public init(text: String, isExpanded: Bool, onReadMore: @escaping () -> Void) {
        self.text = text
        self.isExpanded = isExpanded
        self.onReadMore = onReadMore
    }

    public var body: some View {
        descriptionText
            .lineLimit(isExpanded ? nil : Constants.collapsedLineLimit)
            .frame(maxWidth: .infinity, alignment: .leading)
            .readGeometry(\.size.height, bindTo: $collapsedHeight)
            .overlay(alignment: .bottomTrailing) {
                if showsReadMore {
                    readMore
                }
            }
            .background(alignment: .top) { measuringText }
            .contentShape(.rect)
            .onTapGesture {
                if showsReadMore {
                    onReadMore()
                }
            }
            .accessibilityAddTraits(showsReadMore ? .isButton : [])
    }

    private var descriptionText: some View {
        Text(text)
            .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textSecondary)
    }

    private var readMore: some View {
        Text(Localization.commonReadMore)
            .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
            .lineLimit(1)
            .padding(.leading, Constants.readMoreLeadingPadding)
            .background { readMoreBackdrop }
    }

    private var readMoreBackdrop: some View {
        HStack(spacing: 0) {
            LinearGradient(
                colors: [DesignSystem.Color.bgPrimary.opacity(0), DesignSystem.Color.bgPrimary],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: Constants.readMoreFadeWidth)

            DesignSystem.Color.bgPrimary
        }
        .padding(.leading, -Constants.readMoreFadeWidth)
    }

    private var measuringText: some View {
        descriptionText
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .readGeometry(\.size.height, bindTo: $fullHeight)
            .hidden()
    }
}

// MARK: - Constants

private extension PolymarketExpandableDescription {
    enum Constants {
        static let collapsedLineLimit = 3
        static let heightComparisonTolerance: CGFloat = 1
        static let readMoreLeadingPadding: CGFloat = 4
        static let readMoreFadeWidth: CGFloat = 24
    }
}
