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

    // [REDACTED_TODO_COMMENT]
    // [REDACTED_TODO_COMMENT]
    private let forceKingfisher: Bool

    init(url: URL?, size: CGSize, forceKingfisher: Bool = false) {
        self.url = url
        self.size = size
        self.forceKingfisher = forceKingfisher
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
                    .cornerRadiusContinuous(5)
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
            .renderingMode(.original) // iOS 13 needs this to properly display an image inside a button label
            .cancelOnDisappear(true)
            .setProcessor(DownsamplingImageProcessor(size: size))
            .placeholder { CircleImageTextView(name: "", color: .tangemSkeletonGray) }
            .fade(duration: 0.3)
            .cacheOriginalImage()
            .scaleFactor(UIScreen.main.scale)
            .resizable()
            .scaledToFit()
            .frame(size: size)
            .cornerRadiusContinuous(5)
    }

    private var placeholder: some View {
        SkeletonView()
            .frame(size: size)
            .cornerRadius(size.height / 2)
    }
}

struct IconView_Preview: PreviewProvider {
    static var previews: some View {
        IconView(
            url: TokenIconURLBuilder(baseURL: CoinsResponse.baseURL).iconURL(id: "arbitrum-one", size: .small),
            size: CGSize(width: 40, height: 40)
        )
    }
}
