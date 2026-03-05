//
//  PriceChangeView.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemFoundation

public struct PriceChangeView: View {
    private let state: State
    private let showSkeletonWhenLoading: Bool
    private let showIconForNeutral: Bool
    /// [REDACTED_INFO]: Remove this flag and legacy colors when the redesign feature toggle is deleted
    private let useRedesignColors: Bool

    public init(
        state: State,
        showSkeletonWhenLoading: Bool = true,
        showIconForNeutral: Bool = true,
        useRedesignColors: Bool = false
    ) {
        self.state = state
        self.showSkeletonWhenLoading = showSkeletonWhenLoading
        self.showIconForNeutral = showIconForNeutral
        self.useRedesignColors = useRedesignColors
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
                    SkeletonView()
                        .frame(width: 40, height: 12)
                        .cornerRadiusContinuous(3)
                }
            }
        case .loaded(let changeType, let text):
            HStack(spacing: 4) {
                if shouldShowIcon(for: changeType) {
                    changeType.imageType.image
                        .renderingMode(.template)
                        .foregroundColor(resolvedIconColor(for: changeType))
                }

                styledText(text, textColor: resolvedTextColor(for: changeType))
            }
        }
    }

    private func shouldShowIcon(for changeType: ChangeType) -> Bool {
        if changeType == .neutral {
            return showIconForNeutral
        }
        return true
    }

    private func resolvedTextColor(for changeType: ChangeType) -> Color {
        useRedesignColors ? changeType.color : changeType.legacyColor
    }

    private func resolvedIconColor(for changeType: ChangeType) -> Color {
        useRedesignColors ? changeType.iconColor : changeType.legacyColor
    }

    private var defaultTextColor: Color {
        useRedesignColors ? .Tangem.Text.Neutral.tertiary : Colors.Text.tertiary
    }

    private var styledDashText: some View {
        styledText(String.enDashSign)
    }

    @ViewBuilder
    private func styledText(_ text: String, textColor: Color? = nil) -> some View {
        let color = textColor ?? defaultTextColor
        let font: Font = useRedesignColors ? .Tangem.caption1 : Fonts.Regular.caption1
        Text(text)
            .style(font, color: color)
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
        case loaded(changeType: ChangeType, text: String)

        public var changeType: ChangeType? {
            if case .loaded(let changeType, _) = self {
                return changeType
            }
            return nil
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
                return .Tangem.Text.Status.accent
            case .neutral:
                return .Tangem.Text.Neutral.tertiary
            case .negative:
                return .Tangem.Text.Status.warning
            }
        }

        public var iconColor: Color {
            switch self {
            case .positive:
                .Tangem.Graphic.Status.accent
            case .neutral:
                .Tangem.Graphic.Neutral.tertiary
            case .negative:
                .Tangem.Graphic.Status.warning
            }
        }

        /// [REDACTED_INFO]: Remove legacy colors when the redesign feature toggle is deleted
        public var legacyColor: Color {
            switch self {
            case .positive:
                Colors.Text.accent
            case .neutral:
                Colors.Text.tertiary
            case .negative:
                Colors.Text.warning
            }
        }
    }
}

// MARK: - Previews

#if DEBUG
struct PriceChangeView_Previews: PreviewProvider {
    static var previews: some View {
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
}
#endif // DEBUG
