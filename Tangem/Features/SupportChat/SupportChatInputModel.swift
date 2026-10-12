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
    /// Identifier passed to `usedeskMessenger.userIdentify` for user matching.
    let userIdentifier: String?
    /// Entry point the chat was opened from.
    let source: SupportChatSource
    /// Optional flow context: sets the Usedesk source field and/or auto-sends a message.
    let initialMessage: String?
    let analyticsContextParams: Analytics.ContextParams

    init(
        logsComposer: LogsComposer,
        userIdentifier: String?,
        source: SupportChatSource,
        initialMessage: String? = nil,
        analyticsContextParams: Analytics.ContextParams = .empty
    ) {
        self.logsComposer = logsComposer
        self.userIdentifier = userIdentifier
        self.source = source
        self.initialMessage = initialMessage
        self.analyticsContextParams = analyticsContextParams
    }

    init(
        logsComposer: LogsComposer,
        userWalletId: UserWalletId?,
        source: SupportChatSource,
        initialMessage: String? = nil
    ) {
        self.init(
            logsComposer: logsComposer,
            userIdentifier: userWalletId?.stringValue.lowercased(),
            source: source,
            initialMessage: initialMessage,
            analyticsContextParams: userWalletId.map { .userWallet($0) } ?? .empty
        )
    }

    var topic: SupportChatTopic? {
        source.topic
    }
}
