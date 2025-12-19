//
//  NavigationBar.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUIUtils

public struct ArrowBack: View {
    private let action: () -> Void
    private let height: CGFloat
    private let color: Color

    public init(action: @escaping () -> Void, height: CGFloat, color: Color = Colors.Old.tangemGrayDark6) {
        self.action = action
        self.height = height
        self.color = color
    }

    public var body: some View {
        Button(action: action, label: {
            Image(systemName: "chevron.left")
                .frame(width: height, height: height)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(color)
        })
        .frame(width: height, height: height)
    }
}

public enum DefaultNavigationBarSettings {
    public static let color = Colors.Old.tangemGrayDark6
    public static let padding = 16.0
}

public struct OnboardingCloseButton: View {
    private let height: CGFloat
    private let hPadding: CGFloat
    private let action: () -> Void

    public init(
        height: CGFloat,
        hPadding: CGFloat = DefaultNavigationBarSettings.padding,
        action: @escaping () -> Void
    ) {
        self.height = height
        self.hPadding = hPadding
        self.action = action
    }

    public var body: some View {
        CloseButton(dismiss: action)
            .padding(.horizontal, hPadding)
    }
}

public struct BackButton: View {
    let height: CGFloat
    let isVisible: Bool
    let isEnabled: Bool
    let color: Color
    let hPadding: CGFloat
    let action: () -> Void

    public init(
        height: CGFloat,
        isVisible: Bool,
        isEnabled: Bool,
        color: Color = DefaultNavigationBarSettings.color,
        hPadding: CGFloat = DefaultNavigationBarSettings.padding,
        action: @escaping () -> Void
    ) {
        self.height = height
        self.isVisible = isVisible
        self.isEnabled = isEnabled
        self.color = color
        self.hPadding = hPadding
        self.action = action
    }

    public var body: some View {
        Button(action: action, label: {
            HStack(spacing: 5) {
                Image(systemName: "chevron.left")
                    .padding(-1) // remove default? extra padding
                Text(Localization.commonBack)
                    .font(.system(size: 17, weight: .regular))
            }
        })
        .allowsHitTesting(isEnabled)
        .hidden(!isVisible)
        .frame(height: height)
        .foregroundColor(isEnabled ? color : color.opacity(0.5))
        .padding(.horizontal, hPadding)
    }
}

public struct SupportButton: View {
    let title: String
    let height: CGFloat
    let isVisible: Bool
    let isEnabled: Bool
    let color: Color
    let hPadding: CGFloat
    let action: () -> Void

    public init(
        title: String = Localization.commonSupport,
        height: CGFloat,
        isVisible: Bool,
        isEnabled: Bool,
        color: Color = Colors.Old.tangemGrayDark6,
        hPadding: CGFloat = 16,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.height = height
        self.isVisible = isVisible
        self.isEnabled = isEnabled
        self.color = color
        self.hPadding = hPadding
        self.action = action
    }

    public var body: some View {
        Button(action: action, label: {
            Text(title)
                .font(.system(size: 17, weight: .regular))
        })
        .allowsHitTesting(isEnabled)
        .opacity(isVisible ? 1.0 : 0.0)
        .frame(height: height)
        .foregroundColor(isEnabled ? color : color.opacity(0.5))
        .padding(.horizontal, hPadding)
    }
}

public struct SearchButton: View {
    let height: CGFloat
    let isVisible: Bool
    let isEnabled: Bool
    let color: Color
    let hPadding: CGFloat
    let action: () -> Void

    public init(
        height: CGFloat,
        isVisible: Bool,
        isEnabled: Bool,
        color: Color = Colors.Old.tangemGrayDark6,
        hPadding: CGFloat = 16,
        action: @escaping () -> Void
    ) {
        self.height = height
        self.isVisible = isVisible
        self.isEnabled = isEnabled
        self.color = color
        self.hPadding = hPadding
        self.action = action
    }

    public var body: some View {
        Button(action: action, label: {
            Assets.search.image
                .renderingMode(.template)
                .resizable()
                .foregroundColor(Colors.Icon.primary1)
                .frame(width: 24, height: 24)
                .padding(.all, 4)
        })
        .allowsHitTesting(isEnabled)
        .opacity(isVisible ? 1.0 : 0.0)
        .frame(height: height)
        .foregroundColor(isEnabled ? color : color.opacity(0.5))
        .padding(.horizontal, hPadding)
    }
}

public struct DefaultNavigationBarTitle: View {
    public struct Settings {
        let font: Font
        let color: Color
        let lineLimit: Int?
        let minimumScaleFactor: CGFloat

        public init(
            font: Font = .system(size: 17, weight: .medium),
            color: Color = Colors.Old.tangemGrayDark6,
            lineLimit: Int? = nil, // Default system value
            minimumScaleFactor: CGFloat = 1 // Default system value
        ) {
            self.font = font
            self.color = color
            self.lineLimit = lineLimit
            self.minimumScaleFactor = minimumScaleFactor
        }

        public static var `default` = Settings()
    }

    private let title: String
    private let settings: Settings

    public init(_ title: String, settings: Settings = .default) {
        self.title = title
        self.settings = settings
    }

    public var body: some View {
        Text(title)
            .style(settings.font, color: settings.color)
            .lineLimit(settings.lineLimit)
            .multilineTextAlignment(.center)
            .minimumScaleFactor(settings.minimumScaleFactor)
    }
}

public struct NavigationBar<Title: View, LeftButtons: View, RightButtons: View>: View {
    public struct Settings {
        let title: DefaultNavigationBarTitle.Settings
        let backgroundColor: Color
        let horizontalPadding: CGFloat
        let height: CGFloat
        let alignment: Alignment

        public init(
            title: DefaultNavigationBarTitle.Settings = .default,
            backgroundColor: Color = Colors.Old.tangemBgGray,
            horizontalPadding: CGFloat = 0,
            height: CGFloat = 44,
            alignment: Alignment = .center
        ) {
            self.title = title
            self.backgroundColor = backgroundColor
            self.horizontalPadding = horizontalPadding
            self.height = height
            self.alignment = alignment
        }
    }

    private let settings: Settings

    private let title: () -> Title
    private let leftButtons: () -> LeftButtons
    private let rightButtons: () -> RightButtons

    @State private var titleHorizontalPadding: CGFloat = 0.0

    public init(
        settings: Settings = .init(),
        @ViewBuilder titleView: @escaping () -> Title,
        @ViewBuilder leftButtons: @escaping () -> LeftButtons,
        @ViewBuilder rightButtons: @escaping () -> RightButtons
    ) {
        self.settings = settings
        title = titleView
        self.leftButtons = leftButtons
        self.rightButtons = rightButtons
    }

    public var body: some View {
        ZStack {
            HStack(spacing: 0.0) {
                leftButtons()
                    .readGeometry(\.size.width) { newValue in
                        if newValue > titleHorizontalPadding {
                            titleHorizontalPadding = newValue
                        }
                    }

                Spacer()

                rightButtons()
                    .readGeometry(\.size.width) { newValue in
                        if newValue > titleHorizontalPadding {
                            titleHorizontalPadding = newValue
                        }
                    }
            }

            HStack(spacing: 0.0) {
                FixedSpacer.horizontal(titleHorizontalPadding)
                    .layoutPriority(1)

                title()

                FixedSpacer.horizontal(titleHorizontalPadding)
                    .layoutPriority(1)
            }
        }
        .padding(.horizontal, settings.horizontalPadding)
        .frame(height: settings.height, alignment: settings.alignment)
        .background(settings.backgroundColor.edgesIgnoringSafeArea(.all))
    }
}

public extension NavigationBar where Title == DefaultNavigationBarTitle {
    init(
        title: String,
        settings: Settings = .init(),
        @ViewBuilder leftButtons: @escaping () -> LeftButtons,
        @ViewBuilder rightButtons: @escaping () -> RightButtons
    ) {
        self.title = {
            DefaultNavigationBarTitle(
                title,
                settings: settings.title
            )
        }
        self.settings = settings
        self.rightButtons = rightButtons
        self.leftButtons = leftButtons
    }
}

public extension NavigationBar where LeftButtons == EmptyView {
    init(
        settings: Settings = .init(),
        @ViewBuilder titleView: @escaping () -> Title,
        @ViewBuilder rightButtons: @escaping () -> RightButtons
    ) {
        self.init(
            settings: settings,
            titleView: titleView,
            leftButtons: { EmptyView() },
            rightButtons: rightButtons
        )
    }
}

public extension NavigationBar where RightButtons == EmptyView {
    init(
        settings: Settings = .init(),
        @ViewBuilder titleView: @escaping () -> Title,
        @ViewBuilder leftButtons: @escaping () -> LeftButtons
    ) {
        self.init(
            settings: settings,
            titleView: titleView,
            leftButtons: leftButtons,
            rightButtons: { EmptyView() }
        )
    }
}

public extension NavigationBar where Title == DefaultNavigationBarTitle, LeftButtons == EmptyView {
    init(
        title: String,
        settings: Settings = .init(),
        @ViewBuilder rightButtons: @escaping () -> RightButtons
    ) {
        self.init(
            title: title,
            settings: settings,
            leftButtons: { EmptyView() },
            rightButtons: rightButtons
        )
    }
}

public extension NavigationBar where Title == DefaultNavigationBarTitle, RightButtons == EmptyView {
    init(
        title: String,
        settings: Settings = .init(),
        @ViewBuilder leftButtons: @escaping () -> LeftButtons
    ) {
        self.init(
            title: title,
            settings: settings,
            leftButtons: leftButtons,
            rightButtons: { EmptyView() }
        )
    }
}

public extension NavigationBar where Title == DefaultNavigationBarTitle, LeftButtons == EmptyView, RightButtons == EmptyView {
    init(
        title: String,
        settings: Settings = .init()
    ) {
        self.init(
            title: title,
            settings: settings,
            leftButtons: { EmptyView() },
            rightButtons: { EmptyView() }
        )
    }
}

public extension NavigationBar where LeftButtons == ArrowBack, RightButtons == EmptyView, Title == DefaultNavigationBarTitle {
    init(
        title: String,
        settings: Settings = .init(),
        backAction: @escaping () -> Void
    ) {
        self.init(
            title: title,
            settings: settings,
            leftButtons: {
                ArrowBack(
                    action: {
                        backAction()
                    },
                    height: settings.height
                )
            },
            rightButtons: { EmptyView() }
        )
    }
}

#if DEBUG
#Preview {
    Group {
        VStack {
            NavigationBar(title: "Hello, World!", backAction: {})
            Spacer()
        }.deviceForPreview(.iPhone11Pro)

        VStack {
            NavigationBar(title: "Hello, World!")
            Spacer()
        }.deviceForPreview(.iPhone11ProMax)

        HStack {
            BackButton(height: 44, isVisible: true, isEnabled: true) {}
            Spacer()
        }.deviceForPreview(.iPhone11ProMax)
    }
}
#endif
