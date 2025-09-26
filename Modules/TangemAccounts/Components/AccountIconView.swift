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

    private var padding: CGFloat = 0
    private var cornerRadius: CGFloat = 0
    private var size: CGSize = .init(bothDimensions: 16)

    public init(backgroundColor: Color, nameMode: NameMode) {
        self.backgroundColor = backgroundColor
        self.nameMode = nameMode
    }

    public var body: some View {
        label
            .roundedBackground(with: backgroundColor, padding: padding, radius: cornerRadius)
            .animation(.default, value: nameMode)
    }

    @ViewBuilder
    private var label: some View {
        switch nameMode {
        case .letter(let letter):
            Text(letter)
                .style(Fonts.Bold.largeTitle, color: Colors.Text.constantWhite)

        case .imageType(let imageType, let config):
            imageType.image
                .renderingMode(.template)
                .resizable()
                .frame(size: size)
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
    public func padding(_ value: CGFloat) -> Self {
        map { $0.padding = value }
    }

    public func cornerRadius(_ value: CGFloat) -> Self {
        map { $0.cornerRadius = value }
    }

    public func imageSize(_ value: CGSize) -> Self {
        map { $0.size = value }
    }
}
