//
//  IncomingActionRecorder.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation

/// Writes down what a link is worth on its own the moment it arrives, whatever becomes of the link itself: the
/// referral a promo link carries, the co-brand campaign an AppsFlyer link names. The same things a link coming
/// through the AppsFlyer SDK writes down, and for the same reason — what waits for a screen can be lost.
final class IncomingActionRecorder {
    @Injected(\.incomingActionManager) private var incomingActionManager: IncomingActionManaging
    @Injected(\.referralService) private var referralService: ReferralService

    private var cancellable: AnyCancellable?

    func start() {
        cancellable = incomingActionManager.incomingActionsPublisher
            .withWeakCaptureOf(self)
            .sink { recorder, action in
                recorder.record(action)
            }
    }

    private func record(_ action: IncomingAction) {
        switch action {
        case .navigation(.promo(let deeplink)):
            guard let refcode = deeplink.refcode else {
                return
            }

            AnalyticsLogger.info("Refcode was provided: \(refcode)")
            referralService.saveAndBindIfNeeded(refcode: refcode, campaign: deeplink.campaign)

        case .navigation(.payCustomCard(let deeplink)):
            // The stored key, not the link, is what survives until a screen can show the campaign — the
            // welcome flow spends it before the main screen is ever reached.
            TangemPayCampaignService().markPending(campaignKey: deeplink.campaignKey)

        default:
            break
        }
    }
}
