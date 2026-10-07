//
//  SupportChatInputModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct SupportChatInputModel {
    let logsComposer: LogsComposer
    /// Wallet id passed to `usedeskMessenger.userIdentify` for user matching.
    let userWalletId: UserWalletId?
    /// Entry point the chat was opened from.
    let source: SupportChatSource
    /// Optional flow context: sets the Usedesk source field and/or auto-sends a message.
    let initialMessage: String?

    init(
        logsComposer: LogsComposer,
        userWalletId: UserWalletId?,
        source: SupportChatSource,
        initialMessage: String? = nil
    ) {
        self.logsComposer = logsComposer
        self.userWalletId = userWalletId
        self.source = source
        self.initialMessage = initialMessage
    }

    var userIdentifier: String? {
        userWalletId?.stringValue.lowercased()
    }

    var topic: SupportChatTopic? {
        source.topic
    }

    var analyticsContextParams: Analytics.ContextParams {
        userWalletId.map { .userWallet($0) } ?? .empty
    }
}
