//
//  TokenPromotionNotificationsManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// Promotion notifications manager for token-specific screens (Token Details, Yield).
/// Filters promotions by networkId + tokenAddress.
/// Uses explicit async/await — no Combine, no side effects in init.
final class TokenPromotionNotificationsManager {
    private let userWalletId: UserWalletId
    private let placement: PromotionPlacement
    private let networkId: String
    private let tokenAddress: String
    private let repository: PromotionRepository

    init(
        userWalletId: UserWalletId,
        placement: PromotionPlacement,
        networkId: String,
        tokenAddress: String,
        repository: PromotionRepository? = nil
    ) {
        self.userWalletId = userWalletId
        self.placement = placement
        self.networkId = networkId
        self.tokenAddress = tokenAddress
        self.repository = repository ?? InjectedValues[\.promotionRepository]
    }

    /// Loads and returns filtered notifications for the configured token.
    func loadNotifications() async -> [NotificationViewInput] {
        let promotions = await repository.promotions(
            userWalletId: userWalletId,
            placeholder: placement,
            networkId: networkId,
            tokenAddress: tokenAddress
        )
        return promotions.map(mapToNotificationInput)
    }

    /// Refreshes promotions from the server for this placement.
    func refresh() async {
        await repository.loadPromotions(userWalletId: userWalletId, placeholder: placement)
    }

    /// Hides a promotion (user dismissed it).
    func hidePromotion(displayId: Int) async {
        await repository.hidePromotion(userWalletId: userWalletId, displayId: displayId)
    }
}

// MARK: - Private

private extension TokenPromotionNotificationsManager {
    func mapToNotificationInput(_ promotion: Promotion) -> NotificationViewInput {
        let event = PromotionNotificationEvent(
            promotion: promotion,
            buttonAction: makeButtonAction(for: promotion)
        )

        return NotificationsFactory().buildNotificationInput(
            for: event,
            buttonAction: { [weak self] id, action in
                self?.handleButtonTap(promotion: promotion, action: action)
            },
            dismissAction: { [weak self] _ in
                self?.handleDismiss(promotion: promotion)
            }
        )
    }

    func makeButtonAction(for promotion: Promotion) -> NotificationButtonAction? {
        guard promotion.buttonEnabled, let deeplink = promotion.deeplink else {
            return nil
        }
        return NotificationButtonAction(.openDeeplink(url: deeplink, buttonTitle: promotion.buttonText ?? ""))
    }

    func handleButtonTap(promotion: Promotion, action: NotificationButtonActionType) {
        if case .openDeeplink(let url, _) = action {
            let handler = InjectedValues[\.incomingActionHandler]
            let handled = handler.handleIncomingURL(url)
            PromotionsLogger.info("Token promotion deeplink handled: \(handled)")
        }

        let event = PromotionNotificationEvent(promotion: promotion, buttonAction: nil)
        Analytics.log(event: .promotionBannerButtonClicked, params: event.analyticsParams)
    }

    func handleDismiss(promotion: Promotion) {
        Task { await hidePromotion(displayId: promotion.id) }

        let event = PromotionNotificationEvent(promotion: promotion, buttonAction: nil)
        Analytics.log(event: .promotionBannerDismissed, params: event.analyticsParams)
    }
}
