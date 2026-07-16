//
//  ChatDataCollector.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

/// Builds the pre-filled message and user identity for the support chat opened from a Send/Express flow.
protocol ChatDataCollector {
    var message: String { get }
    /// Wallet id used as `userIdentifier` in the support chat (Usedesk userIdentify).
    var userIdentifier: String? { get }
}

/// Used by flows that don't pre-fill the chat (transfer, approve, staking).
struct EmptyChatDataCollector: ChatDataCollector {
    var message: String { "" }
    var userIdentifier: String? { nil }
}

/// Pre-fills the support chat with the swap operation context.
struct SwapChatDataCollector: ChatDataCollector {
    let userIdentifier: String?
    let fromAddress: String
    let sentToken: String
    let toAddress: String
    let receivedToken: String
    let provider: String
    let providerType: String

    var message: String {
        Localization.supportChatSwapPrefilledMessage(fromAddress, sentToken, toAddress, receivedToken, provider, providerType)
    }
}
