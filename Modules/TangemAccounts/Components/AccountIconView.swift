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
    private var settings = Settings.defaultSized

    public init(data: ViewData) {
        self.data = data
    }

    public var body: some View {
        label
            .frame(size: settings.size)
            .padding(settings.padding)
            .background(
                RoundedRectangle(cornerRadius: settings.cornerRadius, style: .continuous)
                    .fill(data.backgroundColor)
            )
            .animation(.default, value: data.nameMode)
    }

    @ViewBuilder
    private var label: some View {
        switch data.nameMode {
        case .letter(let letter):
            Text(letter)
                .style(settings.letterFontStyle, color: Colors.Text.constantWhite)

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
    }
}

// MARK: - NameMode

public extension AccountIconView {
    enum NameMode: Hashable {
        case letter(String)
        case imageType(ImageType, ImageConfig = .default)
    }
}

// MARK: - Settings

public extension AccountIconView {
    struct Settings {
        let padding: CGFloat
        let cornerRadius: CGFloat
        let size: CGSize
        let letterFontStyle: Font

        public static let largeSized: Self = .init(
            padding: 24,
            cornerRadius: 24,
            size: CGSize(bothDimensions: 34),
            letterFontStyle: Fonts.Bold.largeTitle
        )

        public static let defaultSized: Self = .init(
            padding: 8,
            cornerRadius: 10,
            size: CGSize(bothDimensions: 16),
            letterFontStyle: Fonts.Bold.title3
        )

        public static let mediumSized: Self = .init(
            padding: 8,
            cornerRadius: 10,
            size: CGSize(bothDimensions: 14),
            letterFontStyle: Fonts.Bold.body
        )

        public static let smallSized: Self = .init(
            padding: 4,
            cornerRadius: 6,
            size: CGSize(bothDimensions: 10),
            letterFontStyle: Fonts.Bold.footnote
        )

        public static let extraSmallSized: Self = .init(
            padding: 3,
            cornerRadius: 4,
            size: CGSize(bothDimensions: 8),
            letterFontStyle: Fonts.Bold.caption2
        )
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
        map { $0.settings = settings }
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
