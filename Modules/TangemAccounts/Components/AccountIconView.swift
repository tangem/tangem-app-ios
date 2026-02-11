//
//  AccountIconView.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils
import TangemAssets

public struct AccountIconView: View {
    private let data: ViewData
    private let settings: Settings
    private let iconGeometryEffect: GeometryEffectPropertiesModel?
    private let backgroundGeometryEffect: GeometryEffectPropertiesModel?

    /// [REDACTED_USERNAME] is needed for SwiftUI to adapt numbers to DynamicType properly
    @ScaledMetric
    private var scaledWidth: CGFloat
    @ScaledMetric
    private var scaledHeight: CGFloat
    @ScaledMetric
    private var scaledPadding: CGFloat

    public init(
        data: ViewData,
        settings: Settings = .defaultSized,
        iconGeometryEffect: GeometryEffectPropertiesModel? = nil,
        backgroundGeometryEffect: GeometryEffectPropertiesModel? = nil
    ) {
        self.data = data
        self.settings = settings
        self.iconGeometryEffect = iconGeometryEffect
        self.backgroundGeometryEffect = backgroundGeometryEffect
        _scaledWidth = ScaledMetric(wrappedValue: settings.size.width)
        _scaledHeight = ScaledMetric(wrappedValue: settings.size.height)
        _scaledPadding = ScaledMetric(wrappedValue: settings.padding)
    }

    public var body: some View {
        label
            .matchedGeometryEffect(iconGeometryEffect)
            .frame(width: scaledWidth, height: scaledHeight)
            .padding(scaledPadding)
            .background(
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: geo.size.width * Constants.cornerRadiusRatio, style: .continuous)
                        .fill(data.backgroundColor)
                }
                .matchedGeometryEffect(backgroundGeometryEffect)
            )
            .animation(.default, value: data.nameMode)
    }

    @ViewBuilder
    private var label: some View {
        switch data.nameMode {
        case .letter(let letter, let config):
            Text(letter)
                .style(settings.letterFontStyle, color: Colors.Text.constantWhite)
                // Needed for scale animation. E.g. on Main
                .minimumScaleFactor(config.minimumScaleFactor)

        case .imageType(let imageType, let config):
            imageType.image
                .renderingMode(.template)
                .resizable()
                .foregroundStyle(Colors.Text.constantWhite)
                .opacity(config.opacity)
        }
    }
}

// MARK: - AccountIconViewData

public extension AccountIconView {
    struct ViewData: Hashable {
        let backgroundColor: Color
        let nameMode: NameMode

        public init(backgroundColor: Color, nameMode: NameMode) {
            self.backgroundColor = backgroundColor
            self.nameMode = nameMode
        }

        /// Applies the given letter config if the name mode is `.letter`.
        /// Returns unchanged data for other name modes.
        public func applyingLetterConfig(_ config: NameMode.LetterConfig) -> Self {
            switch nameMode {
            case .letter(let letter, _):
                return ViewData(backgroundColor: backgroundColor, nameMode: .letter(letter, config))
            case .imageType:
                return self
            }
        }
    }
}

// MARK: - Constants

private extension AccountIconView {
    enum Constants {
        static let cornerRadiusRatio: CGFloat = 0.28
    }
}

// MARK: - NameMode

public extension AccountIconView {
    enum NameMode: Hashable {
        case letter(String, LetterConfig = .default)
        case imageType(ImageType, ImageConfig = .default)
    }
}

// MARK: - Settings

public extension AccountIconView {
    struct Settings {
        public let padding: CGFloat
        public let size: CGSize
        let letterFontStyle: Font

        public static let largeSized: Self = .init(
            padding: 24,
            size: CGSize(bothDimensions: 34),
            letterFontStyle: Fonts.Bold.largeTitle
        )

        public static let defaultSized: Self = .init(
            padding: 8,
            size: CGSize(bothDimensions: 20),
            letterFontStyle: Fonts.Bold.title3
        )

        public static let mediumSized: Self = .init(
            padding: 8,
            size: CGSize(bothDimensions: 14),
            letterFontStyle: Fonts.Bold.body
        )

        public static let smallSized: Self = .init(
            padding: 4,
            size: CGSize(bothDimensions: 10),
            letterFontStyle: Fonts.Bold.footnote
        )

        public static let extraSmallSized: Self = .init(
            padding: 3,
            size: CGSize(bothDimensions: 8),
            letterFontStyle: Fonts.Bold.caption2
        )
    }
}

// MARK: - LetterConfig

public extension AccountIconView.NameMode {
    struct LetterConfig: Hashable {
        let minimumScaleFactor: CGFloat

        public init(minimumScaleFactor: CGFloat = 1.0) {
            self.minimumScaleFactor = minimumScaleFactor
        }

        public static let `default`: Self = LetterConfig()
    }
}

// MARK: - ImageConfig

public extension AccountIconView.NameMode {
    struct ImageConfig: Hashable {
        let opacity: Double

        public init(opacity: Double = 1) {
            self.opacity = opacity
        }

        public static let `default`: Self = ImageConfig()
    }
}

// MARK: - Setupable

extension AccountIconView: Setupable {
    public func settings(_ settings: Settings) -> Self {
        AccountIconView(data: data, settings: settings, iconGeometryEffect: iconGeometryEffect, backgroundGeometryEffect: backgroundGeometryEffect)
    }

    public func iconGeometryEffect(_ effect: GeometryEffectPropertiesModel?) -> Self {
        AccountIconView(data: data, settings: settings, iconGeometryEffect: effect, backgroundGeometryEffect: backgroundGeometryEffect)
    }

    public func backgroundGeometryEffect(_ effect: GeometryEffectPropertiesModel?) -> Self {
        AccountIconView(data: data, settings: settings, iconGeometryEffect: iconGeometryEffect, backgroundGeometryEffect: effect)
    }
}

// MARK: - Previews

#Preview("Icon With Image") {
    HStack {
        AccountIconView(data: .init(backgroundColor: .blue, nameMode: .imageType(Assets.Accounts.starAccounts)))
        AccountIconView(data: .init(backgroundColor: .blue, nameMode: .imageType(Assets.Accounts.starAccounts)))
            .settings(.largeSized)
        AccountIconView(data: .init(backgroundColor: .blue, nameMode: .imageType(Assets.Accounts.starAccounts)))
            .settings(.mediumSized)
        AccountIconView(data: .init(backgroundColor: .blue, nameMode: .imageType(Assets.Accounts.starAccounts)))
            .settings(.smallSized)
        AccountIconView(data: .init(backgroundColor: .blue, nameMode: .imageType(Assets.Accounts.starAccounts)))
            .settings(.extraSmallSized)
    }
}

#Preview("Icon With Text") {
    HStack {
        AccountIconView(data: .init(backgroundColor: .blue, nameMode: .letter("A")))
        AccountIconView(data: .init(backgroundColor: .blue, nameMode: .letter("A")))
            .settings(.largeSized)
        AccountIconView(data: .init(backgroundColor: .blue, nameMode: .letter("A")))
            .settings(.mediumSized)
        AccountIconView(data: .init(backgroundColor: .blue, nameMode: .letter("A")))
            .settings(.smallSized)
        AccountIconView(data: .init(backgroundColor: .blue, nameMode: .letter("A")))
            .settings(.extraSmallSized)
    }
}
