//
//  NotificationBanner.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils
import TangemAssets

public struct NotificationBanner: View, Setupable {
    private let bannerType: BannerType

    @ScaledMetric private var padding: CGFloat
    @ScaledMetric private var iconSize: CGFloat

    public init(bannerType: BannerType) {
        self.bannerType = bannerType
        _padding = ScaledMetric(wrappedValue: SizeUnit.x3.value)
        _iconSize = ScaledMetric(wrappedValue: bannerType.content.iconSize)
    }

    private var content: Content { bannerType.content }
    private var buttons: Buttons { bannerType.buttons }

    private var isCentered: Bool {
        if bannerType.isClosable { return false }

        switch content {
        case .text: return true
        case .textWithIcon: return false
        }
    }

    public var body: some View {
        VStack(spacing: SizeUnit.x4.value) {
            contentView
            buttonsView
        }
        .padding(padding)
        .frame(maxWidth: .infinity, alignment: isCentered ? .center : .leading)
        .overlay(alignment: .topTrailing) {
            if bannerType.isClosable {
                closeButton
            }
        }
        .glowBorder(effect: bannerType.effect)
    }

    private var closeButton: some View {
        Button(action: { bannerType.closeAction?() }) {
            Circle()
                .fill(Color.Tangem.Graphic.Neutral.secondary)
                .frame(size: .init(bothDimensions: SizeUnit.x5.value))
                .overlay {
                    Assets.cross16.image
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundStyle(
                            Color.Tangem.Fill.Neutral.bannerBackground
                        )
                        .padding(SizeUnit.half.value)
                }
                .padding(SizeUnit.x3.value)
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if bannerType.isClosable {
            textStack(title: content.text.title, subtitle: content.text.subtitle)
        } else {
            switch content {
            case .text(let textOnly):
                textStack(title: textOnly.title, subtitle: textOnly.subtitle)

            case .textWithIcon(let data):
                HStack(spacing: SizeUnit.x2.value) {
                    textStack(title: data.text.title, subtitle: data.text.subtitle)

                    Spacer()

                    data.icon.imageType.image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(
                            width: iconSize,
                            height: iconSize,
                            alignment: data.icon.alignment.verticalAlignment
                        )
                }
            }
        }
    }

    private func textStack(title: AttributedString, subtitle: AttributedString) -> some View {
        let alignment: HorizontalAlignment = isCentered ? .center : .leading
        let textAlignment: TextAlignment = isCentered ? .center : .leading

        return VStack(alignment: alignment, spacing: SizeUnit.x1.value) {
            Text(title)
                .style(
                    Fonts.Bold.headline,
                    color: Color.Tangem.Text.Neutral.primary
                )
                .multilineTextAlignment(textAlignment)

            Text(subtitle)
                .style(
                    Fonts.Bold.subheadline,
                    color: Color.Tangem.Text.Neutral.tertiary
                )
                .multilineTextAlignment(textAlignment)
        }
    }

    @ViewBuilder
    private var buttonsView: some View {
        switch buttons {
        case .none:
            EmptyView()
        case .one(let model):
            TangemButton(model: model)
        case .two(let left, let right):
            HStack(spacing: SizeUnit.x3.value) {
                TangemButton(model: left)
                TangemButton(model: right)
            }
        }
    }
}
