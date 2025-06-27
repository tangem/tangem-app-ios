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
                .shimmer()
                .networkIconOverlay(imageAsset: iconOverlayImage) // This reusable UI component has its own shimmer

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
    }

    private var textsView: some View {
        VStack(alignment: .leading, spacing: Constants.textsSpacing) {
            Text(title)
                .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
                .shimmer()

            Text(subtitle)
                .style(Fonts.Bold.caption1, color: Colors.Text.tertiary)
                .shimmer()
        }
    }

    @ViewBuilder
    private var icon: some View {
        if let media {
            makeMedia(media)
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
                forceKingfisher: true,
                placeholder: { placeholder }
            )

        case .animation:
            GIFImage(url: media.url, placeholder: placeholder)
                .frame(size: Constants.Icon.size)
                .cornerRadiusContinuous(Constants.Icon.cornerRadius)

        case .video, .audio, .unknown:
            placeholder
        }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: Constants.Icon.cornerRadius)
            .fill(Colors.Field.focused)
            .frame(size: Constants.Icon.size)
    }
}

extension NFTCollectionRow {
    enum Constants {
        enum Icon {
            static let size: CGSize = .init(bothDimensions: 36)
            static let cornerRadius: CGFloat = 8
        }

        static let iconTextsSpacing: CGFloat = 12
        static let textsSpacing: CGFloat = 2
        static let chevronSize: CGSize = .init(bothDimensions: 24)
        static let rotationAnimation: Animation = .spring(response: 0.6, dampingFraction: 0.9, blendDuration: 0.5)
    }
}

#if DEBUG
#Preview {
    ZStack {
        Color.gray
            .ignoresSafeArea()

        VStack {
            NFTCollectionRow(
                media: .init(
                    kind: .animation,
                    url: URL(
                        string: "https://i.seadn.io/gcs/files/e31424bc14dd91a653cb01857cac52a4.gif?w=500&auto=format"
                    )!
                ),
                iconOverlayImage: Tokens.ethereumFill,
                title: "Nethers",
                subtitle: "2 items",
                isExpanded: false
            )
            .padding(.horizontal, 16)
        }
    }
}
#endif
