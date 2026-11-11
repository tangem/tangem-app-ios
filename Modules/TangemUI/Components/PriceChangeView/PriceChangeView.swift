//
//  PriceChangeView.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils
import TangemFoundation

public struct PriceChangeView: View {
    private let state: State
    private let showSkeletonWhenLoading: Bool
    private let showIconForNeutral: Bool
    private let skeletonSize: CGSize

    public init(
        state: State,
        showSkeletonWhenLoading: Bool = true,
        showIconForNeutral: Bool = true,
        skeletonSize: CGSize = CGSize(width: 40, height: 12)
    ) {
        self.state = state
        self.showSkeletonWhenLoading = showSkeletonWhenLoading
        self.showIconForNeutral = showIconForNeutral
        self.skeletonSize = skeletonSize
    }

    public var body: some View {
        switch state {
        case .initialized:
            styledDashText
                .opacity(0.01)
        case .noData:
            styledDashText
        case .empty:
            Text("")
        case .loading:
            ZStack {
                styledDashText
                    .opacity(0.01)
                if showSkeletonWhenLoading {
                    skeleton
                }
            }
        case .loaded(let changeType, let text):
            changeContent(changeType: changeType, text: text)
        case .loadingCached(let changeType, let text):
            changeContent(changeType: changeType, text: text)
                .shimmering(true)
        }
    }

    private func changeContent(changeType: ChangeType, text: String) -> some View {
        HStack(spacing: 4) {
            if shouldShowIcon(for: changeType) {
                changeType.imageType.image
                    .renderingMode(.template)
                    .foregroundColor(changeType.iconColor)
            }

            styledText(text, textColor: changeType.color)
        }
    }

    private var skeleton: some View {
        Shimmer()
            .variant(.custom(width: skeletonSize.width, height: skeletonSize.height))
    }

    private func shouldShowIcon(for changeType: ChangeType) -> Bool {
        if changeType == .neutral {
            return showIconForNeutral
        }
        return true
    }

    private var defaultTextColor: Color {
        DesignSystem.Color.textSecondary
    }

    private var styledDashText: some View {
        styledText(String.enDashSign)
    }

    private func styledText(_ text: String, textColor: Color? = nil) -> some View {
        Text(text)
            .style(DesignSystem.Font.captionMediumToken, color: textColor ?? defaultTextColor)
            .lineLimit(1)
    }
}

// MARK: - State

public extension PriceChangeView {
    enum State: Hashable {
        case initialized
        case noData
        case empty
        case loading
        case loadingCached(changeType: ChangeType, text: String)
        case loaded(changeType: ChangeType, text: String)

        public var changeType: ChangeType? {
            switch self {
            case .loaded(let changeType, _), .loadingCached(let changeType, _):
                return changeType
            default:
                return nil
            }
        }
    }
}

// MARK: - ChangeType

public extension PriceChangeView {
    enum ChangeType: Int, Hashable {
        case positive
        case neutral
        case negative

        public init(from value: Decimal) {
            if value == .zero {
                self = .neutral
            } else if value > 0 {
                self = .positive
            } else {
                self = .negative
            }
        }

        public var imageType: ImageType {
            switch self {
            case .positive:
                return Assets.quotePositive
            case .neutral:
                return Assets.quoteNeutral
            case .negative:
                return Assets.quoteNegative
            }
        }

        public var color: Color {
            switch self {
            case .positive:
                return DesignSystem.Color.textAccentBlue
            case .neutral:
                return DesignSystem.Color.textSecondary
            case .negative:
                return DesignSystem.Color.textAccentRed
            }
        }

        public var iconColor: Color {
            switch self {
            case .positive:
                DesignSystem.Color.iconAccentBlue
            case .neutral:
                DesignSystem.Color.iconSecondary
            case .negative:
                DesignSystem.Color.iconAccentRed
            }
        }
    }
}

// MARK: - Previews

#Preview {
    VStack(spacing: 16) {
        PriceChangeView(state: .initialized)
        PriceChangeView(state: .noData)
        PriceChangeView(state: .loading)
        PriceChangeView(state: .loading, showSkeletonWhenLoading: false)
        PriceChangeView(state: .loaded(changeType: .positive, text: "+2.34%"))
        PriceChangeView(state: .loaded(changeType: .neutral, text: "0.00%"))
        PriceChangeView(state: .loaded(changeType: .neutral, text: "0.00%"), showIconForNeutral: false)
        PriceChangeView(state: .loaded(changeType: .negative, text: "-1.23%"))
    }
    .padding()
}
