//
//  PolymarketFastTradingStrings.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

// [REDACTED_TODO_COMMENT]
enum PolymarketFastTradingStrings {
    static let title = "Fast trading"
    static let settingsTitle = "Settings"
    static let whatIsFastTrading = "What is fast trading?"
    static let thisDevice = "This device"
    static let otherDevices = "Other devices"
    static let onboardingToggleTitle = "Enable fast trading for up to 180 days. Pause it anytime."
    static let unknownDevice = "Unknown device"
    static let foreignSigner = "Unknown signer"

    static let reactivate = "Reactivate"
    static let extend = "Extend"
    static let extendFor180Days = "Extend for 180 days"
    static let revoke = "Revoke"
    static let pause = "Pause fast trading"
    static let resume = "Resume fast trading"

    static let statusActivating = "Activation"
    static let statusActivationFailed = "Activation failed"
    static let statusActive = "Active"
    static let statusPaused = "Paused"
    static let statusExpired = "Expired"
    static let statusOutOfSync = "Reconnect needed"
    static let statusRevoking = "Revoking"

    static let activationBannerTitle = "Activate fast trading for your device"
    static let activationBannerDescription = "It's secured and you can use fast bets without tapping your card. It lasts up to 180 days."
    static let extensionBannerDescription = "Extend it by 180 days with one card tap to keep placing fast bets without tapping your card."

    static let activationInProgress = "Activation in progress"
    static let extensionInProgress = "Extension in progress"
    static let revocationInProgress = "Revoking fast trading"

    static let infoTitle = "Trade Predictions without tapping your Tangem card or ring every time"
    static let durationCaption = "How long it lasts"
    static let durationValue = "Up to 180 days"
    static let nameCaption = "What it's called"
    static let nameValue = "Session key"

    static let whatItIs = Section(
        title: "What is it?",
        text: "A temporary key stored on this device. You approve it once with your Tangem card or ring, and it signs your Polymarket buy/sell orders from then on."
    )

    static let howLongItLasts = Section(
        title: "How long does it last?",
        text: "Up to 180 days. Renewing it takes one card tap."
    )

    static let whatItCanDo = Section(
        title: "What can it do?",
        text: "Send buy and sell orders instantly without tapping your Tangem card or ring. That's ideal for live sports, esports and fast crypto markets, where you need a light touch to place an order quickly."
    )

    static let whatItCantDo = Section(
        title: "What can't it do?",
        text: "Move your money. Deposits and withdrawals always need a tap of your Tangem card or ring."
    )

    static let youAreInControl = Section(
        title: "You are in control",
        text: "See every active session key (one per device). Pause any of them anytime, or revoke one with a Tangem tap. Switch it off on this phone and every order will need a tap again."
    )

    static let revocationTitle = "Revoke fast trading?"
    static let foreignDescription = "Someone else can trade with your predictions balance. If you didn't allow it, revoke these signers now."
    static let foreignBannerTitle = "Unknown signers can trade"

    static let staleSignature = "The signature has expired. Sign again."
    static let deviceBusy = "Another change is in progress. Try again in a minute."
    static let changeInProgress = "Another fast trading change is still in progress. Wait until it finishes and try again."
    static let revocationPending = "Waiting for the revocation to finish. You can activate fast trading on this device right after."
    static let limitReached = "Too many devices use fast trading. Revoke the ones you don't use."
    static let notReady = "Finish setting up predictions first."

    static func until(_ date: String) -> String {
        "Until \(date)"
    }

    static func activeUntil(_ date: String) -> String {
        "Active until \(date)"
    }

    static func expiredAt(_ date: String) -> String {
        "At \(date)"
    }

    static func expiresIn(days: Int) -> String {
        days == 1 ? "Expires in 1 day" : "Expires in \(days) days"
    }

    static func extensionBannerTitle(daysLeft: Int) -> String {
        daysLeft == 1 ? "Fast trading expires in 1 day" : "Fast trading expires in \(daysLeft) days"
    }

    static func revocationDescription(_ title: String) -> String {
        "Orders signed on \(title) stop working once the revocation goes through. You can activate fast trading on it again later."
    }

    static func foreignSignerRevocationDescription(_ title: String) -> String {
        "Orders signed by \(title) stop working once the revocation goes through."
    }
}

// MARK: - Section

extension PolymarketFastTradingStrings {
    struct Section: Hashable {
        let title: String
        let text: String
    }
}
