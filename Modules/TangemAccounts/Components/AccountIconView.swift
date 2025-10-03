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
    private let backgroundColor: Color
    private let nameMode: NameMode

    private var settings = Settings()

    public init(backgroundColor: Color, nameMode: NameMode) {
        self.backgroundColor = backgroundColor
        self.nameMode = nameMode
    }

    public var body: some View {
        label
            .frame(size: settings.size)
            .roundedBackground(with: backgroundColor, padding: settings.padding, radius: settings.cornerRadius)
            .animation(.default, value: nameMode)
    }

    @ViewBuilder
    private var label: some View {
        switch nameMode {
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

// MARK: - NameMode

public extension AccountIconView {
    enum NameMode: Equatable {
        case letter(String)
        case imageType(ImageType, ImageConfig = .default)
    }
}

// MARK: - Settings

public extension AccountIconView {
    struct Settings {
        var padding: CGFloat = 0
        var cornerRadius: CGFloat = 0
        var size: CGSize = .init(bothDimensions: 16)
        var letterFontStyle: Font = Fonts.Bold.largeTitle

        static let middleSized: Self = .init(
            padding: 8,
            cornerRadius: 10,
            size: CGSize(bothDimensions: 20),
            letterFontStyle: Fonts.BoldStatic.title3
        )
    }
}

// MARK: - ImageConfig

public extension AccountIconView.NameMode {
    struct ImageConfig: Equatable {
        let opacity: Double

        public init(opacity: Double = 1) {
            self.opacity = opacity
        }

        public static let `default`: Self = ImageConfig()
    }
}

// MARK: - Setupable

extension AccountIconView: Setupable {
    public func setMiddleSizedIconSettings() -> Self {
        map { $0.settings = .middleSized }
    }

    public func padding(_ value: CGFloat) -> Self {
        map { $0.settings.padding = value }
    }

    public func cornerRadius(_ value: CGFloat) -> Self {
        map { $0.settings.cornerRadius = value }
    }

    public func size(_ value: CGSize) -> Self {
        map { $0.settings.size = value }
    }

    public func letterFontStyle(_ value: Font) -> Self {
        map { $0.settings.letterFontStyle = value }
    }
}
