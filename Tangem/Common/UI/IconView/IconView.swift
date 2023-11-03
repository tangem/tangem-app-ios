//
//  IconView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import Kingfisher

struct IconView: View {
    private let url: URL?
    private let size: CGSize
    private let lowContrastBackgroundColor: UIColor
    private var cornerRadius: CGFloat = 5

    // [REDACTED_TODO_COMMENT]
    // [REDACTED_TODO_COMMENT]
    private let forceKingfisher: Bool

    private static var defaultLowContrastBackgroundColor: UIColor {
        UIColor.backgroundPrimary.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
    }

    init(url: URL?, size: CGSize, lowContrastBackgroundColor: UIColor = Self.defaultLowContrastBackgroundColor, forceKingfisher: Bool = false) {
        self.url = url
        self.size = size
        self.lowContrastBackgroundColor = lowContrastBackgroundColor
        self.forceKingfisher = forceKingfisher
    }

    init(url: URL?, sizeSettings: IconViewSizeSettings, lowContrastBackgroundColor: UIColor = Self.defaultLowContrastBackgroundColor, forceKingfisher: Bool = false) {
        self.init(url: url, size: sizeSettings.iconSize, lowContrastBackgroundColor: lowContrastBackgroundColor, forceKingfisher: forceKingfisher)
    }

    var body: some View {
        if forceKingfisher {
            kfImage
        } else if #available(iOS 15.0, *) {
            cachedAsyncImage
        } else {
            kfImage
        }
    }

    @available(iOS 15.0, *)
    var cachedAsyncImage: some View {
        CachedAsyncImage(url: url, scale: UIScreen.main.scale) { phase in
            switch phase {
            case .empty:
                placeholder
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
            .placeholder { CircleImageTextView(name: "", color: Colors.Button.secondary, size: size) }
            .fade(duration: 0.3)
            .cacheOriginalImage()
            .resizable()
            .scaledToFit()
            .frame(size: size)
            .cornerRadiusContinuous(cornerRadius)
    }

    private var placeholder: some View {
        SkeletonView()
            .frame(size: size)
            .cornerRadius(size.height / 2)
    }
}

extension IconView: Setupable {
    func cornerRadius(_ radius: CGFloat) -> Self {
        map { $0.cornerRadius = radius }
    }
}

struct IconView_Preview: PreviewProvider {
    static var previews: some View {
        IconView(
            url: TokenIconURLBuilder().iconURL(id: "arbitrum-one", size: .small),
            size: CGSize(width: 40, height: 40)
        )
    }
}
