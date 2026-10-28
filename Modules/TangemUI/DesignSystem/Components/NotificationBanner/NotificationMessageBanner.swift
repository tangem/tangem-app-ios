//
//  NotificationMessageBanner.swift
//  TangemModules
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils
import TangemAssets
import TangemLocalization

public struct NotificationMessageBanner: View {
    private let bannerType: NotificationBanner.BannerType
    private let variantOverride: MessageBannerVariant?
    private let ringOverride: NotificationBanner.Ring?
    private let textColors: MessageBannerOverrideTextColors
    private let accessibilityIdentifier: String?

    public init(
        bannerType: NotificationBanner.BannerType,
        variant: MessageBannerVariant? = nil,
        ring: NotificationBanner.Ring? = nil,
        textColors: MessageBannerOverrideTextColors = .init(),
        accessibilityIdentifier: String?
    ) {
        self.bannerType = bannerType
        variantOverride = variant
        ringOverride = ring
        self.textColors = textColors
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    public var body: some View {
        banner
            .accessibilityIdentifier(accessibilityIdentifier)
    }

    private var banner: some View {
        let (title, description) = titleAndSubtitle
        let (variant, ring) = variantAndRing
        let buttons = mappedButtons

        let base = MessageBanner(title: title, description: description)
            .variant(variant)
            .glowRing(ringAppearance(ring))
            .overrideTextColors(textColors)
            .contentAlign(contentAlign)
            .secondaryButton(buttons.secondary)
            .primaryButton(buttons.primary)
            .onTap(tapAction)

        return withSlots(base)
    }

    @ViewBuilder
    private func withSlots(_ base: MessageBanner<EmptyView, EmptyView, EmptyView>) -> some View {
        switch (iconSlot, closeAction) {
        case (nil, nil):
            base
        case (nil, let close?):
            base.closeButton(accessibilityLabel: Localization.commonClose, action: close)
        case (let icon?, nil):
            if icon.isTrailing {
                base.slotEnd { iconView(for: icon) }
            } else {
                base.slotStart { iconView(for: icon) }
            }
        case (let icon?, let close?):
            base.slotStart { iconView(for: icon) }.closeButton(accessibilityLabel: Localization.commonClose, action: close)
        }
    }
}

// MARK: - Mapping

private extension NotificationMessageBanner {
    var titleAndSubtitle: (AttributedString, AttributedString?) {
        let text = bannerType.content.text
        let subtitle = text.subtitle.characters.isEmpty ? nil : text.subtitle

        if text.title.characters.isEmpty, let subtitle {
            return (subtitle, nil)
        }

        return (text.title, subtitle)
    }

    var variantAndRing: (MessageBannerVariant?, NotificationBanner.Ring) {
        let (variant, ring): (MessageBannerVariant?, NotificationBanner.Ring) = switch bannerType {
        case .critical: (.error, ringOverride ?? .error)
        case .warning: (.warning, ringOverride ?? .warning)
        case .promo, .survey, .informational: (nil, ringOverride ?? .magic)
        case .status: (nil, ringOverride ?? .off)
        }

        return (variantOverride ?? variant, ring)
    }

    var contentAlign: MessageBannerContentAlign {
        switch bannerType.textAlignment {
        case .leading:
            return .start
        case .center:
            if case .text = bannerType.content {
                return .center
            }
            return .start
        }
    }

    var closeAction: (() -> Void)? {
        bannerType.closeAction.map { $0.action }
    }

    var tapAction: (() -> Void)? {
        guard case .tappable(let action) = bannerType.bannerAction else { return nil }
        return action.action
    }

    enum IconSlot {
        case image(NotificationBanner.Icon)
        case loadable(url: URL, size: CGSize)

        var isTrailing: Bool {
            guard case .image(let icon) = self else { return false }
            return icon.isLeading == false
        }
    }

    var iconSlot: IconSlot? {
        switch bannerType.content {
        case .text:
            return nil
        case .textWithIcon(let data):
            return .image(data.icon)
        case .textWithLoadableIcon(let data):
            return .loadable(url: data.icon.url, size: bannerType.content.iconSize)
        }
    }

    @ViewBuilder
    func iconView(for slot: IconSlot) -> some View {
        switch slot {
        case .image(let icon):
            iconImage(for: icon)
        case .loadable(let url, let size):
            IconView(url: url, size: size)
        }
    }

    func iconImage(for icon: NotificationBanner.Icon) -> some View {
        icon.imageType.image
            .renderingMode(icon.renderingMode)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: icon.width, height: icon.height)
            .foregroundColor(icon.color)
    }

    var mappedButtons: (primary: MessageBannerButton?, secondary: MessageBannerButton?) {
        guard case .buttons(let buttons) = bannerType.bannerAction else {
            return (nil, nil)
        }

        switch buttons {
        case .none:
            return (nil, nil)
        case .one(let item):
            let button = messageBannerButton(from: item)
            return item.isSecondary ? (nil, button) : (button, nil)
        case .two(let left, let right):
            let leftButton = messageBannerButton(from: left)
            let rightButton = messageBannerButton(from: right)

            if right.isSecondary, !left.isSecondary {
                return (leftButton, rightButton)
            }

            return (rightButton, leftButton)
        }
    }

    func ringAppearance(_ ring: NotificationBanner.Ring) -> GlowRingAppearance? {
        switch ring {
        case .off: nil
        case .magic: .magic
        case .warning: .warning
        case .error: .error
        case .info: .info
        }
    }

    func messageBannerButton(from item: NotificationBanner.ButtonItem) -> MessageBannerButton {
        let title: String
        let iconStart: ImageType?
        let iconEnd: ImageType?

        switch item.model.content {
        case .label(let text, let start, let end):
            title = String(text.characters)
            iconStart = start
            iconEnd = end
        case .iconOnly(let image):
            title = ""
            iconStart = image
            iconEnd = nil
        }

        return MessageBannerButton(
            title: title,
            iconStart: iconStart,
            iconEnd: iconEnd,
            isLoading: item.isLoading,
            accessibilityLabel: item.model.accessibilityLabel,
            accessibilityIdentifier: item.accessibilityIdentifier,
            action: item.model.action
        )
    }
}
