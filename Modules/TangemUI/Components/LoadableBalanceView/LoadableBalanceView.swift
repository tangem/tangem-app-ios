//
//  LoadableBalanceView.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemAccessibilityIdentifiers
import TangemUIUtils
import TangemFoundation

public struct LoadableBalanceView: View {
    let state: State
    let style: Style
    let loader: LoaderStyle
    let accessibilityIdentifier: String?

    private var contentTransitionType: ContentTransitionType?

    public init(
        state: State,
        style: Style,
        loader: LoaderStyle,
        accessibilityIdentifier: String? = nil
    ) {
        self.state = state
        self.style = style
        self.loader = loader
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    public var body: some View {
        Group {
            switch state {
            case .loading(.some(let cached)):
                textView(cached)
                    .shimmer()
                    .accessibilityIdentifier(accessibilityIdentifier.map { "\($0)Shimmer" })
            case .loading(.none):
                RoundedRectangle(cornerRadius: loader.cornerRadius, style: .continuous)
                    .fill(Color.Tangem.Skeleton.backgroundPrimary)
                    .frame(size: loader.size)
                    .padding(loader.padding)
                    .shimmer()
                    .accessibilityIdentifier(accessibilityIdentifier.map { "\($0)Shimmer" })
            case .failed(let text, .none):
                textView(text)
            case .failed(let text, .leading):
                HStack(spacing: 6) {
                    cloudIcon

                    textView(text)
                }
            case .failed(let text, .trailing):
                HStack(spacing: 6) {
                    textView(text)

                    cloudIcon
                }
            case .loaded(let text):
                textView(text)
            }
        }
        .environment(\.isShimmerActive, true)
    }

    private var cloudIcon: some View {
        Assets.failedCloud.image
            .resizable()
            .renderingMode(.template)
            .foregroundStyle(Color.Tangem.Graphic.Neutral.quaternary)
            .frame(size: CGSize(bothDimensions: .unit(.x3)))
    }

    @ViewBuilder
    private func textView(_ text: Text) -> some View {
        SensitiveText(text)
            .style(style.font, color: style.textColor)
            .applyContentTransition(type: contentTransitionType, text: text)
            .accessibilityIdentifier(accessibilityIdentifier)
    }
}

// MARK: - Types

public extension LoadableBalanceView {
    typealias Text = SensitiveText.TextType

    enum State: Hashable {
        case loading(cached: Text? = nil)
        case failed(cached: Text, icon: Icon? = nil)
        case loaded(text: Text)

        public enum Icon: Hashable {
            case leading
            case trailing
        }

        // Convenient

        public static let empty: State = .loaded(text: .string(.enDashSign))
        public static func loaded(text: String) -> State { .loaded(text: .string(text)) }

        public var isFailed: Bool {
            if case .failed = self {
                return true
            }

            return false
        }
    }

    struct Style {
        public let font: Font
        public let textColor: Color

        public init(font: Font, textColor: Color) {
            self.font = font
            self.textColor = textColor
        }
    }

    struct LoaderStyle {
        public let size: CGSize
        public let padding: EdgeInsets
        public let cornerRadius: CGFloat

        public init(size: CGSize, padding: EdgeInsets = .init(), cornerRadius: CGFloat = 3) {
            self.size = size
            self.padding = padding
            self.cornerRadius = cornerRadius
        }
    }
}

// MARK: - ContentTransitionType

public extension LoadableBalanceView {
    enum ContentTransitionType {
        case numeric(isCountdown: Bool)

        var contentTransition: ContentTransition? {
            switch self {
            case .numeric(let isCountdown): .numericText(countsDown: isCountdown)
            }
        }
    }
}

private extension View {
    @ViewBuilder
    func applyContentTransition(type: LoadableBalanceView.ContentTransitionType?, text: SensitiveText.TextType) -> some View {
        switch type {
        case .numeric(let isCountdown):
            if #available(iOS 17, *) {
                self
                    .contentTransition(.numericText(countsDown: isCountdown))
                    .animation(.default, value: text)
            } else {
                self
            }

        case nil:
            self
        }
    }
}

// MARK: - Setupable

extension LoadableBalanceView: Setupable {
    public func setContentTransition(_ transitionType: ContentTransitionType?) -> Self {
        map { $0.contentTransitionType = transitionType }
    }
}

// MARK: - Previews

#if DEBUG

// MARK: - Previews

struct LoadableBalanceView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .trailing, spacing: 16) {
            VStack(alignment: .trailing, spacing: 2) {
                LoadableBalanceView(
                    state: .loading(cached: .string("1 312 422,23 $")),
                    style: .init(font: Font.Tangem.subheadline, textColor: Color.Tangem.Text.Neutral.primary),
                    loader: .init(size: .init(width: 40, height: 12))
                )

                LoadableBalanceView(
                    state: .loading(cached: .string("1,23 BTC")),
                    style: .init(font: Font.Tangem.caption1, textColor: Color.Tangem.Text.Neutral.tertiary),
                    loader: .init(size: .init(width: 40, height: 12))
                )
            }

            Divider()

            VStack(alignment: .trailing, spacing: 2) {
                LoadableBalanceView(
                    state: .loading(cached: .none),
                    style: .init(font: Font.Tangem.subheadline, textColor: Color.Tangem.Text.Neutral.primary),
                    loader: .init(size: .init(width: 40, height: 12))
                )

                LoadableBalanceView(
                    state: .loading(cached: .none),
                    style: .init(font: Font.Tangem.caption1, textColor: Color.Tangem.Text.Neutral.tertiary),
                    loader: .init(size: .init(width: 40, height: 12))
                )
            }

            Divider()

            VStack(alignment: .trailing, spacing: 2) {
                LoadableBalanceView(
                    state: .loaded(text: .string("1 312 422,23 $")),
                    style: .init(font: Font.Tangem.subheadline, textColor: Color.Tangem.Text.Neutral.primary),
                    loader: .init(size: .init(width: 40, height: 12))
                )

                LoadableBalanceView(
                    state: .loaded(text: .string("1,23 BTC")),
                    style: .init(font: Font.Tangem.caption1, textColor: Color.Tangem.Text.Neutral.tertiary),
                    loader: .init(size: .init(width: 40, height: 12))
                )
            }

            Divider()

            VStack(alignment: .trailing, spacing: 2) {
                LoadableBalanceView(
                    state: .failed(cached: .string("1 312 422,23 $"), icon: .leading),
                    style: .init(font: Font.Tangem.subheadline, textColor: Color.Tangem.Text.Neutral.primary),
                    loader: .init(size: .init(width: 40, height: 12))
                )

                LoadableBalanceView(
                    state: .failed(cached: .string("1,23 BTC")),
                    style: .init(font: Font.Tangem.caption1, textColor: Color.Tangem.Text.Neutral.tertiary),
                    loader: .init(size: .init(width: 40, height: 12))
                )
            }
        }
        .padding()
    }
}
#endif // DEBUG
