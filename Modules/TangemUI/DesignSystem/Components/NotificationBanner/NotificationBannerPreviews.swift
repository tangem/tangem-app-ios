//
//  NotificationBannerPreviews.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

// MARK: - Showcase

public struct NotificationBannerShowcase: View {
    private let stackingType: NotificaitonBannerContainerStackingType

    @State private var items: [ShowcaseItem] = []

    public init(stackingType: NotificaitonBannerContainerStackingType) {
        self.stackingType = stackingType
    }

    public var body: some View {
        ScrollView {
            VStack {
                NotificationBannerContainer(
                    items: items,
                    stackingType: stackingType
                )
            }
        }
        .onAppear {
            if items.isEmpty {
                items = makeItems()
            }
        }
    }
}

// MARK: - Private

private extension NotificationBannerShowcase {
    struct ShowcaseItem: NotificationBannerContainerItem {
        let id: UUID
        let bannerType: NotificationBanner.BannerType
    }

    func removeItem(id: UUID) {
        withAnimation {
            items.removeAll { $0.id == id }
        }
    }

    func button(_ title: AttributedString, style: TangemButton.StyleType, itemId: UUID) -> TangemButton.Model {
        .init(content: .text(title), styleType: style, cornerStyle: .rounded, action: {
            Task { @MainActor in removeItem(id: itemId) }
        })
    }

    func closeAction(itemId: UUID) -> NotificationBanner.CloseAction {
        .init {
            Task { @MainActor in removeItem(id: itemId) }
        }
    }

    func makeItems() -> [ShowcaseItem] {
        let ids = (0 ..< 7).map { _ in UUID() }

        return [
            ShowcaseItem(
                id: ids[0],
                bannerType: .critical(
                    .textWithIcon(.init(
                        text: .init(
                            title: "Security alert",
                            subtitle: "It seems that the card or ring activation was not completed correctly. This could be due to an issue with your device's NFC module or incorrect tapping of the card or ring to your device. Please contact our Support team for assistance."
                        ),
                        icon: .init(imageType: Assets.notificationBell, alignment: .center)
                    )),
                    .two(
                        left: button("Dismiss", style: .secondary, itemId: ids[0]),
                        right: button("Got it", style: .primary, itemId: ids[0])
                    )
                )
            ),
            ShowcaseItem(
                id: ids[1],
                bannerType: .warning(
                    .text(.init(
                        title: "Finalize wallet setup",
                        subtitle: "To complete setup, back up your wallet and secure thew app with an access code"
                    )),
                    .two(
                        left: button("Dismiss", style: .secondary, itemId: ids[1]),
                        right: button("Got it", style: .primary, itemId: ids[1])
                    )
                )
            ),
            ShowcaseItem(
                id: ids[2],
                bannerType: .status(
                    .text(.init(
                        title: "Demo mode",
                        subtitle: "Feel free top explore. This isn't your real wallet."
                    ))
                )
            ),
            ShowcaseItem(
                id: ids[3],
                bannerType: .critical(
                    .textWithIcon(.init(
                        text: .init(
                            title: "Don't miss a transaction",
                            subtitle: "Enable push notifications to receive alerts when funds arrive in your wallet."
                        ),
                        icon: .init(imageType: Assets.notificationBell, alignment: .center)
                    )),
                    .two(
                        left: button("Settings", style: .secondary, itemId: ids[3]),
                        right: button("Enable notifications", style: .primary, itemId: ids[3])
                    )
                )
            ),
            ShowcaseItem(
                id: ids[4],
                bannerType: .promo(
                    .init(
                        title: "Tangem Visa Card",
                        subtitle: "Join the waitlist and get a payment card unlike any other"
                    ),
                    .one(button("Got it", style: .primary, itemId: ids[4])),
                    closeAction(itemId: ids[4]),
                    .bannerMagic
                )
            ),
            ShowcaseItem(
                id: ids[5],
                bannerType: .informational(
                    .init(
                        title: "Backup your wallet",
                        subtitle: "Protect your assets by creating a backup of your wallet seed phrase."
                    ),
                    .two(
                        left: button("Dismiss", style: .secondary, itemId: ids[5]),
                        right: button("Got it", style: .primary, itemId: ids[5])
                    ),
                    closeAction(itemId: ids[5])
                )
            ),
            ShowcaseItem(
                id: ids[6],
                bannerType: .promo(
                    .init(
                        title: "Rate your experience",
                        subtitle: "Help us improve by sharing your feedback about the app."
                    ),
                    .two(
                        left: button("Dismiss", style: .secondary, itemId: ids[6]),
                        right: button("Got it", style: .primary, itemId: ids[6])
                    ),
                    closeAction(itemId: ids[6]),
                    .bannerCard
                )
            ),
        ]
    }
}

// MARK: - Previews

#if DEBUG

#Preview("Stack") {
    NotificationBannerShowcase(stackingType: .stack)
        .preferredColorScheme(.dark)
}

#Preview("Carousel") {
    NotificationBannerShowcase(stackingType: .carousel)
        .preferredColorScheme(.dark)
}

#endif // DEBUG
