//
//  SupportChatInputModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct SupportChatInputModel {
    let logsComposer: LogsComposer
    /// Wallet id passed to `usedeskMessenger.userIdentify` for user matching.
    let userIdentifier: String?
    /// Entry point the chat was opened from.
    let source: Analytics.SupportChatSource
    /// Optional flow context: sets the Usedesk source field and/or auto-sends a message.
    let initialMessage: SupportInitialMessage?

    init(
        logsComposer: LogsComposer,
        userIdentifier: String?,
        source: Analytics.SupportChatSource,
        initialMessage: SupportInitialMessage? = nil
    ) {
        self.logsComposer = logsComposer
        self.userIdentifier = userIdentifier
        self.source = source
        self.initialMessage = initialMessage
    }
}
