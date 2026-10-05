//
//  MessageBannerShowcase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if INTERNAL || DEBUG
import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct MessageBannerShowcase: View {
    @State private var titleInput = "Invite friends. Earn 10 USDT."
    @State private var descriptionInput = "Share Tangem, give 10% OFF to your friends, and earn 10 USDT for every wallet they activate."
    @State private var variant: MessageBannerVariant = .default
    @State private var contentAlign: MessageBannerContentAlign = .start
    @State private var glowRing: GlowRingAppearance? = .magic
    @State private var hasDescription = true
    @State private var hasSecondaryButton = true
    @State private var hasPrimaryButton = true
    @State private var isTappable = false
    @State private var hasCloseButton = false
    @State private var hasSlotStart = false
    @State private var hasSlotEnd = false
    @State private var hasExtraContent = false
    @State private var isCustomText = false
    @State private var isFocusRingOn = false
    @State private var titleLineLimit = 3
    @State private var descriptionLineLimit = 3
    @State private var lastAction = "none"
    @FocusState private var isBannerFocused: Bool

    var body: some View {
        DSShowcase("MessageBanner") { controls in
            controls.text("Title", $titleInput)
            controls.text("Description", $descriptionInput)
            controls.picker("Variant", $variant)
            controls.picker("Content align", $contentAlign)
            controls.picker("Glow ring", $glowRing)
            controls.toggle("Description", $hasDescription)
            controls.toggle("Tappable", $isTappable)
            if !isTappable {
                controls.toggle("Secondary button", $hasSecondaryButton)
                controls.toggle("Primary button", $hasPrimaryButton)
            }
            controls.toggle("Close button", $hasCloseButton)
            controls.toggle("Slot start", $hasSlotStart)
            if !hasCloseButton {
                controls.toggle("Slot end", $hasSlotEnd)
            }
            controls.toggle("Extra content", $hasExtraContent)
            controls.toggle("Attributed text", $isCustomText)
            controls.toggle("Focus ring", $isFocusRingOn)
            controls.value("Title line limit", $titleLineLimit, in: 1 ... 5)
            controls.value("Description line limit", $descriptionLineLimit, in: 1 ... 5)
            controls.readout("Last action", lastAction)
        } stage: {
            focusableBanner
        } matrix: {
            DSShowcaseGroup("Variants") {
                DSShowcaseMatrix(rows: MessageBannerVariant.allCases) { variant in
                    MessageBanner(title: "Staking rewards are ready", description: "Claim 0.0421 ETH earned this week")
                        .variant(variant)
                        .secondaryButton(MessageBannerButton(title: "Later") {})
                        .primaryButton(MessageBannerButton(title: "Claim") {})
                        .frame(width: Constants.cellWidth)
                }
            }

            DSShowcaseGroup("Content align") {
                DSShowcaseMatrix(rows: MessageBannerContentAlign.allCases) { align in
                    MessageBanner(title: "Invite friends. Earn 10 USDT.", description: "Share Tangem, give 10% OFF, and earn 10 USDT.")
                        .contentAlign(align)
                        .secondaryButton(MessageBannerButton(title: "Later") {})
                        .primaryButton(MessageBannerButton(title: "Invite") {})
                        .frame(width: Constants.cellWidth)
                }
            }

            DSShowcaseGroup("Slots & close") {
                VStack(spacing: 16) {
                    MessageBanner(title: "Backup is not finished", description: "Add a second card to keep access to your funds")
                        .closeButton(accessibilityLabel: "Dismiss") {}
                        .secondaryButton(MessageBannerButton(title: "Later") {})
                        .primaryButton(MessageBannerButton(title: "Continue") {})

                    MessageBanner(title: "Invite friends. Earn 10 USDT.", description: "Share Tangem, give 10% OFF, and earn 10 USDT.")
                        .slotStart { leadingIcon }
                        .primaryButton(MessageBannerButton(title: "Invite friends") {})
                }
                .frame(width: Constants.cellWidth)
            }

            DSShowcaseGroup("Tappable") {
                DSShowcaseMatrix(rows: MessageBannerVariant.allCases) { variant in
                    MessageBanner(title: "Market Pulse", description: "Bitcoin is up 4.2% in the last 24 hours")
                        .variant(variant)
                        .glowRing(ring(for: variant))
                        .onTap {}
                        .frame(width: Constants.cellWidth)
                }

                VStack(spacing: 12) {
                    MessageBanner(title: "Tappable, no glow ring", description: "The whole banner is the button")
                        .onTap {}

                    MessageBanner(title: "Closable and tappable", description: "Tap the body to open, the cross to dismiss")
                        .closeButton(accessibilityLabel: "Dismiss") {}
                        .onTap {}

                    MessageBanner(title: "Buttons, not tappable", description: "Only the buttons react")
                        .secondaryButton(MessageBannerButton(title: "Later") {})
                        .primaryButton(MessageBannerButton(title: "Invite") {})
                }
                .frame(width: Constants.cellWidth)
            }
        }
    }

    @ViewBuilder
    private var focusableBanner: some View {
        if #available(iOS 17.0, *) {
            liveBanner
                .focusable()
                .focused($isBannerFocused)
                .focusEffectDisabled()
                .onChange(of: isFocusRingOn) { _, newValue in isBannerFocused = newValue }
                .onChange(of: isBannerFocused) { _, newValue in isFocusRingOn = newValue }
        } else {
            liveBanner
        }
    }

    private var liveBanner: some View {
        baseBanner
            .slotStart {
                if hasSlotStart { leadingIcon }
            }
            .slotEnd {
                if hasCloseButton {
                    MessageBannerCloseButton(accessibilityLabel: "Dismiss") { lastAction = "close" }
                } else if hasSlotEnd {
                    circlePlaceholder
                }
            }
            .extraBottom {
                if hasExtraContent { protectedByRow }
            }
            .variant(variant)
            .contentAlign(contentAlign)
            .glowRing(glowRing)
            .titleLineLimit(titleLineLimit)
            .descriptionLineLimit(descriptionLineLimit)
            .secondaryButton(!isTappable && hasSecondaryButton ? MessageBannerButton(title: "Later") { lastAction = "secondary" } : nil)
            .primaryButton(!isTappable && hasPrimaryButton ? MessageBannerButton(title: "Invite") { lastAction = "primary" } : nil)
            .onTap(isTappable ? { lastAction = "tap" } : nil)
    }

    private var baseBanner: MessageBanner<EmptyView, EmptyView, EmptyView> {
        let description = hasDescription ? descriptionInput : nil

        if isCustomText {
            return MessageBanner(title: attributedTitle, description: description.map { AttributedString($0) })
        }

        return MessageBanner(title: titleInput, description: description)
    }

    private var attributedTitle: AttributedString {
        var title = AttributedString(titleInput)
        title.foregroundColor = DesignSystem.Color.textStatusSuccess
        title.underlineStyle = .single
        return title
    }

    private var leadingIcon: some View {
        DesignSystem.Icons.Bell.regular24.image
            .renderingMode(.template)
            .resizable()
            .frame(width: 24, height: 24)
            .foregroundStyle(DesignSystem.Color.iconInverse)
            .frame(width: 40, height: 40)
            .background(DesignSystem.Color.bgInverse, in: Circle())
    }

    private var circlePlaceholder: some View {
        Circle()
            .fill(DesignSystem.Color.bgTertiary)
            .frame(width: 24, height: 24)
    }

    private var protectedByRow: some View {
        HStack(spacing: 6) {
            Text("Protected by Tangem Security")
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textPrimary)

            DesignSystem.Icons.ShieldCheckmark.regular20.image
                .renderingMode(.template)
                .resizable()
                .frame(width: 16, height: 16)
                .foregroundStyle(DesignSystem.Color.iconStatusInfo)
        }
    }

    private func ring(for variant: MessageBannerVariant) -> GlowRingAppearance {
        switch variant {
        case .default, .solid: .magic
        case .success: .success
        case .error: .error
        case .warning: .warning
        case .info: .info
        }
    }
}

private extension MessageBannerShowcase {
    enum Constants {
        static let cellWidth: CGFloat = 320
    }
}
#endif
