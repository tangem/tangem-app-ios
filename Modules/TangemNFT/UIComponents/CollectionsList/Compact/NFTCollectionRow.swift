//
//  NFTCollectionRow.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemUIUtils
import Kingfisher

struct NFTCollectionRow: View {
    let media: NFTMedia?
    let iconOverlayImage: ImageType
    let title: String
    let subtitle: String
    let isExpanded: Bool

    var body: some View {
        HStack(spacing: Constants.iconTextsSpacing) {
            icon
            textsView
            Spacer()
            Assets.chevronDown24.image
                .resizable()
                .frame(size: Constants.chevronSize)
                .foregroundStyle(Colors.Icon.inactive)
                .rotationEffect(.degrees(isExpanded ? 180 : 0))
                .animation(Constants.rotationAnimation, value: isExpanded)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(
            height: Constants.Icon.size.height + abs(Constants.Icon.Overlay.offset.height)
        )
    }

    private var textsView: some View {
        VStack(alignment: .leading, spacing: Constants.textsSpacing) {
            Text(title)
                .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

            Text(subtitle)
                .style(Fonts.Bold.caption1, color: Colors.Text.tertiary)
        }
    }

    @ViewBuilder
    private var icon: some View {
        if let media {
            makeMedia(media)
                .background(Colors.Background.primary)
                .overlay(alignment: .topTrailing) {
                    iconOverlayImage.image
                        .resizable()
                        .frame(size: Constants.Icon.Overlay.size)
                        .stroked(
                            color: Colors.Background.primary,
                            cornerRadius: Constants.Icon.Overlay.size.width / 2,
                            lineWidth: Constants.Icon.Overlay.strokeLineWidth
                        )
                        .offset(Constants.Icon.Overlay.offset)
                }
        } else {
            placeholder
        }
    }

    @ViewBuilder
    private func makeMedia(_ media: NFTMedia) -> some View {
        switch media.kind {
        case .image:
            IconView(
                url: media.url,
                size: Constants.Icon.size,
                cornerRadius: Constants.Icon.cornerRadius,
                forceKingfisher: true
            )

        case .animation:
            GIFImage(url: media.url, placeholder: placeholder)

        case .video, .audio, .unknown:
            placeholder
        }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: Constants.Icon.cornerRadius)
            .fill(Colors.Field.primary)
            .frame(size: Constants.Icon.size)
    }
}

extension NFTCollectionRow {
    enum Constants {
        enum Icon {
            static let size: CGSize = .init(bothDimensions: 36)
            static let cornerRadius: CGFloat = 8

            enum Overlay {
                static let size: CGSize = .init(bothDimensions: 16)
                static let strokeLineWidth: CGFloat = 2
                static let offset: CGSize = .init(width: 4, height: -4)
            }
        }

        static let iconTextsSpacing: CGFloat = 12
        static let textsSpacing: CGFloat = 2
        static let chevronSize: CGSize = .init(bothDimensions: 24)
        static let rotationAnimation: Animation = .spring(response: 0.6, dampingFraction: 0.9, blendDuration: 0.5)
    }
}

#if DEBUG
#Preview {
    NFTCollectionRow(
        media: .init(
            kind: .image,
            url: URL(
                string: "https://cusethejuice.s3.amazonaws.com/cuse-box/assets/compressed-collection.png"
            )!
        ),
        iconOverlayImage: Tokens.ethereumFill,
        title: "Nethers",
        subtitle: "2 items",
        isExpanded: false
    )
    .padding(.horizontal, 16)
}
#endif
