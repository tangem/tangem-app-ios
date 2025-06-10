//
//  IconView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import Kingfisher
import TangemAssets
import TangemUIUtils

public struct IconView<Placeholder: View>: View {
    private let url: URL?
    private let size: CGSize
    private let cornerRadius: CGFloat
    private let lowContrastBackgroundColor: UIColor

    // [REDACTED_TODO_COMMENT]
    // [REDACTED_TODO_COMMENT]
    private let forceKingfisher: Bool

    private let placeholder: Placeholder

    public init(
        url: URL?,
        size: CGSize,
        cornerRadius: CGFloat = IconViewDefaults.cornerRadius,
        lowContrastBackgroundColor: UIColor = IconViewDefaults.lowContrastBackgroundColor,
        forceKingfisher: Bool = false,
        @ViewBuilder placeholder: () -> Placeholder
    ) {
        self.url = url
        self.size = size
        self.cornerRadius = cornerRadius
        self.lowContrastBackgroundColor = lowContrastBackgroundColor
        self.forceKingfisher = forceKingfisher
        self.placeholder = placeholder()
    }

    public init(
        url: URL?,
        sizeSettings: IconViewSizeSettings,
        cornerRadius: CGFloat = IconViewDefaults.cornerRadius,
        lowContrastBackgroundColor: UIColor = IconViewDefaults.lowContrastBackgroundColor,
        forceKingfisher: Bool = false,
        @ViewBuilder placeholder: () -> Placeholder
    ) {
        self.init(
            url: url,
            size: sizeSettings.iconSize,
            cornerRadius: cornerRadius,
            lowContrastBackgroundColor: lowContrastBackgroundColor,
            forceKingfisher: forceKingfisher,
            placeholder: placeholder
        )
    }

    public var body: some View {
        if forceKingfisher {
            kfImage
        } else {
            cachedAsyncImage
        }
    }

    var cachedAsyncImage: some View {
        CachedAsyncImage(url: url, scale: UIScreen.main.scale) { phase in
            switch phase {
            case .empty:
                loadingPlaceholder
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
                    .frame(size: size)
                    .cornerRadiusContinuous(cornerRadius)
            case .failure:
                Circle()
                    .fill(Color.clear)
                    .frame(size: size)
                    .overlay(
                        Circle()
                            .stroke(Colors.Icon.informative, lineWidth: 1)
                    )
                    .cornerRadius(size.height / 2)
            @unknown default:
                EmptyView()
            }
        }
    }

    var kfImage: some View {
        KFImage(url)
            .appendProcessor(ContrastBackgroundImageProcessor(backgroundColor: lowContrastBackgroundColor))
            .cancelOnDisappear(true)
            .placeholder { placeholder }
            .fade(duration: 0.3)
            .cacheOriginalImage()
            .resizable()
            .frame(size: size)
            .scaledToFit()
            .cornerRadiusContinuous(cornerRadius)
    }

    private var loadingPlaceholder: some View {
        SkeletonView()
            .frame(size: size)
            .cornerRadius(size.height / 2)
    }
}

// Extension to support default placeholder

public extension IconView where Placeholder == CircleImageTextView {
    init(
        url: URL?,
        size: CGSize,
        cornerRadius: CGFloat = IconViewDefaults.cornerRadius,
        lowContrastBackgroundColor: UIColor = IconViewDefaults.lowContrastBackgroundColor,
        forceKingfisher: Bool = false
    ) {
        self.init(
            url: url,
            size: size,
            cornerRadius: cornerRadius,
            lowContrastBackgroundColor: lowContrastBackgroundColor,
            forceKingfisher: forceKingfisher
        ) {
            CircleImageTextView(name: "", color: Colors.Button.secondary, size: size)
        }
    }

    init(
        url: URL?,
        sizeSettings: IconViewSizeSettings,
        cornerRadius: CGFloat = IconViewDefaults.cornerRadius,
        lowContrastBackgroundColor: UIColor = IconViewDefaults.lowContrastBackgroundColor,
        forceKingfisher: Bool = false
    ) {
        self.init(
            url: url,
            sizeSettings: sizeSettings,
            cornerRadius: cornerRadius,
            lowContrastBackgroundColor: lowContrastBackgroundColor,
            forceKingfisher: forceKingfisher
        ) {
            CircleImageTextView(name: "", color: Colors.Button.secondary, size: sizeSettings.iconSize)
        }
    }
}

public enum IconViewDefaults {
    public static let cornerRadius: CGFloat = 5
    public static let lowContrastBackgroundColor = UIColor.backgroundPrimary
        .resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
}
