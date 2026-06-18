//
//  NotificationBanner.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemFoundation
import TangemUIUtils
import TangemAssets
import TangemAccessibilityIdentifiers

public struct NotificationBanner: View, Setupable {
    private let bannerType: BannerType
    private let accessibilityIdentifier: String?

    @ScaledMetric private var padding: CGFloat
    @ScaledMetric private var iconWidth: CGFloat
    @ScaledMetric private var iconHeight: CGFloat

    private let cornerRadius: CGFloat = .unit(.x6)

    public init(bannerType: BannerType, accessibilityIdentifier: String?) {
        self.bannerType = bannerType
        self.accessibilityIdentifier = accessibilityIdentifier
        let iconSize = bannerType.content.iconSize
        _padding = ScaledMetric(wrappedValue: SizeUnit.x3.value)
        _iconWidth = ScaledMetric(wrappedValue: iconSize.width)
        _iconHeight = ScaledMetric(wrappedValue: iconSize.height)
    }

    private var content: Content { bannerType.content }

    private var isCentered: Bool {
        switch bannerType.textAlignment {
        case .leading: return false
        case .center:
            switch content {
            case .text: return true
            case .textWithIcon, .textWithLoadableIcon: return false
            }
        }
    }

    private var iconIsLeading: Bool {
        switch bannerType {
        case .promo:
            true
        case .status, .critical, .warning, .survey, .informational:
            false
        }
    }

    public var body: some View {
        bannerContent
            .accessibilityIdentifier(accessibilityIdentifier)
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(bannerType.borderColor, lineWidth: .unit(.quarter))
                    .allowsHitTesting(false)
            }
            .overlay(alignment: .topTrailing) {
                if bannerType.isClosable {
                    closeButton
                }
            }
    }

    @ViewBuilder
    private var bannerContent: some View {
        switch bannerType.bannerAction {
        case .buttons(.none):
            bannerBody()
                .accessibilityElement(children: .combine)
        case .buttons(let buttons):
            bannerBody {
                buttonsView(buttons: buttons)
            }
            .accessibilityElement(children: .contain)
        case .tappable(let tapAction):
            Button(action: tapAction.action) {
                bannerBody()
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
        }
    }

    @ViewBuilder
    private func bannerBody<Buttons: View>(
        @ViewBuilder buttons: () -> Buttons = { EmptyView() }
    ) -> some View {
        VStack(alignment: isCentered ? .center : .leading, spacing: SizeUnit.x4.value) {
            contentView
            buttons()
        }
        .padding(padding)
        .frame(maxWidth: .infinity, alignment: isCentered ? .center : .leading)
        .glowBorder(effect: bannerType.effect, cornerRadius: cornerRadius)
    }

    private var closeButton: some View {
        Button(action: { bannerType.closeAction?() }) {
            Circle()
                .fill(Color.Tangem.Graphic.Neutral.secondary)
                .frame(size: .init(bothDimensions: SizeUnit.x5.value))
                .overlay {
                    Assets.DesignSystem.closeSmall.image
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
        switch content {
        case .text(let textOnly):
            textStack(title: textOnly.title, subtitle: textOnly.subtitle)

        case .textWithIcon(let data):
            HStack(
                alignment: data.icon.alignment.verticalAlignment,
                spacing: iconIsLeading ? SizeUnit.x1.value : SizeUnit.x2.value
            ) {
                if iconIsLeading {
                    iconImage(for: data.icon)
                    textStack(title: data.text.title, subtitle: data.text.subtitle)
                    Spacer(minLength: 0)
                } else {
                    textStack(title: data.text.title, subtitle: data.text.subtitle)
                    Spacer()
                    iconImage(for: data.icon)
                }
            }

        case .textWithLoadableIcon(let data):
            HStack(
                alignment: data.icon.alignment.vertical,
                spacing: SizeUnit.x2.value
            ) {
                if data.icon.alignment.horizontal == .leading {
                    IconView(url: data.icon.url, size: content.iconSize)
                    textStack(title: data.text.title, subtitle: data.text.subtitle)
                    Spacer(minLength: 0)
                } else {
                    textStack(title: data.text.title, subtitle: data.text.subtitle)
                    Spacer(minLength: 0)
                    IconView(url: data.icon.url, size: content.iconSize)
                }
            }
        }
    }

    private func iconImage(for icon: Icon) -> some View {
        icon.imageType.image
            .renderingMode(icon.renderingMode)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: iconWidth, height: iconHeight)
    }

    private var closeButtonClearance: CGFloat {
        bannerType.isClosable ? SizeUnit.x6.value : 0
    }

    private func textStack(title: AttributedString, subtitle: AttributedString) -> some View {
        let alignment: HorizontalAlignment = isCentered ? .center : .leading
        let textAlignment: TextAlignment = isCentered ? .center : .leading

        return VStack(alignment: alignment, spacing: SizeUnit.x1.value) {
            if title.characters.isNotEmpty {
                Text(title)
                    .style(
                        Font.Tangem.Body16.medium,
                        color: .Tangem.Text.Neutral.primary
                    )
                    .lineLimit(nil)
                    .multilineTextAlignment(textAlignment)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier(CommonUIAccessibilityIdentifiers.notificationTitle)
            }

            if subtitle.characters.isNotEmpty {
                Text(subtitle)
                    .style(
                        Font.Tangem.Caption12.semibold,
                        color: .Tangem.Text.Neutral.secondary
                    )
                    .lineLimit(nil)
                    .multilineTextAlignment(textAlignment)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier(CommonUIAccessibilityIdentifiers.notificationMessage)
            }
        }
        .padding(.horizontal, SizeUnit.x1.value)
        .padding(isCentered ? .horizontal : .trailing, closeButtonClearance)
        .padding(.top, SizeUnit.x1.value)
    }

    @ViewBuilder
    private func buttonsView(buttons: Buttons) -> some View {
        switch buttons {
        case .none:
            EmptyView()
        case .one(let model, let identifier):
            TangemButton(model: model)
                .accessibilityIdentifier(identifier)
        case .two(let left, let right, let leftIdentifier, let rightIdentifier):
            HStack(spacing: SizeUnit.x3.value) {
                TangemButton(model: left)
                    .accessibilityIdentifier(leftIdentifier)
                TangemButton(model: right)
                    .accessibilityIdentifier(rightIdentifier)
            }
        }
    }
}
