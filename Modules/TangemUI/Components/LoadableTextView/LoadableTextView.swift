//
//  LoadableTextView.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemFoundation

public struct LoadableTextView: View {
    private let state: State
    private let font: Font
    private let textColor: Color
    private let loaderSize: CGSize
    private let loaderCornerRadiusStyle: CornerRadiusStyle
    private let lineLimit: Int
    private let isSensitiveText: Bool

    public init(
        state: State,
        font: Font,
        textColor: Color,
        loaderSize: CGSize,
        loaderCornerRadiusStyle: CornerRadiusStyle = .rounded(3.0),
        lineLimit: Int = 1,
        isSensitiveText: Bool = false
    ) {
        self.state = state
        self.font = font
        self.textColor = textColor
        self.loaderSize = loaderSize
        self.loaderCornerRadiusStyle = loaderCornerRadiusStyle
        self.lineLimit = lineLimit
        self.isSensitiveText = isSensitiveText
    }

    /// Convenience initializer for backward compatibility with `loaderCornerRadius` parameter.
    public init(
        state: State,
        font: Font,
        textColor: Color,
        loaderSize: CGSize,
        loaderCornerRadius: CGFloat,
        lineLimit: Int = 1,
        isSensitiveText: Bool = false
    ) {
        self.init(
            state: state,
            font: font,
            textColor: textColor,
            loaderSize: loaderSize,
            loaderCornerRadiusStyle: .rounded(loaderCornerRadius),
            lineLimit: lineLimit,
            isSensitiveText: isSensitiveText
        )
    }

    public var body: some View {
        content
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .initialized:
            styledDashText
                .opacity(0.01)
        case .noData:
            styledDashText
        case .loading:
            ZStack {
                styledDashText
                    .opacity(0.01)
                skeletonView
                    .frame(width: loaderSize.width, height: loaderSize.height)
            }
        case .loaded(let text):
            styledText(text, isSensitive: isSensitiveText)
        }
    }

    @ViewBuilder
    private var skeletonView: some View {
        switch loaderCornerRadiusStyle {
        case .rounded(let radius):
            SkeletonView()
                .cornerRadiusContinuous(radius)
        case .capsule:
            SkeletonView()
                .clipShape(Capsule())
        }
    }

    private var styledDashText: some View {
        styledText(String.enDashSign, isSensitive: false)
    }

    @ViewBuilder
    private func styledText(_ text: String, isSensitive: Bool) -> some View {
        Group {
            if isSensitive {
                SensitiveText(text)
            } else {
                Text(text)
            }
        }
        .style(font, color: textColor)
        .lineLimit(lineLimit)
    }
}

// MARK: - State

public extension LoadableTextView {
    enum State: Hashable {
        case initialized
        case noData
        case loading
        case loaded(text: String)
    }
}

// MARK: - CornerRadiusStyle

public extension LoadableTextView {
    enum CornerRadiusStyle {
        case rounded(CGFloat)
        case capsule
    }
}

// MARK: - Previews

#if DEBUG
struct LoadableTextView_Previews: PreviewProvider {
    static let states: [(LoadableTextView.State, UUID)] = [
        (.initialized, UUID()),
        (.noData, UUID()),
        (.loading, UUID()),
        (.loaded(text: "Some random text"), UUID()),
        (.loading, UUID()),
    ]

    static var previews: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Rounded (default)")
                    .font(.caption)
                    .foregroundColor(.gray)

                HStack(spacing: 8) {
                    LoadableTextView(
                        state: .loading,
                        font: .Tangem.Caption12.regular,
                        textColor: .Tangem.Text.Neutral.tertiary,
                        loaderSize: .init(width: 40, height: 12)
                    )

                    LoadableTextView(
                        state: .loaded(text: "0.21432543264 ETH"),
                        font: .Tangem.Caption12.regular,
                        textColor: .Tangem.Text.Neutral.tertiary,
                        loaderSize: .init(width: 40, height: 12)
                    )
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Capsule style")
                    .font(.caption)
                    .foregroundColor(.gray)

                HStack(spacing: 8) {
                    LoadableTextView(
                        state: .loading,
                        font: .Tangem.Caption12.regular,
                        textColor: .Tangem.Text.Neutral.tertiary,
                        loaderSize: .init(width: 40, height: 12),
                        loaderCornerRadiusStyle: .capsule
                    )

                    LoadableTextView(
                        state: .loaded(text: "0.21432543264 ETH"),
                        font: .Tangem.Caption12.regular,
                        textColor: .Tangem.Text.Neutral.tertiary,
                        loaderSize: .init(width: 40, height: 12),
                        loaderCornerRadiusStyle: .capsule
                    )
                }
            }

            Divider()

            ForEach(states.indexed(), id: \.1.1) { _, state in
                LoadableTextView(
                    state: state.0,
                    font: .Tangem.Caption12.regular,
                    textColor: .Tangem.Text.Neutral.tertiary,
                    loaderSize: .init(width: 100, height: 20)
                )
            }
        }
        .padding()
    }
}
#endif // DEBUG
