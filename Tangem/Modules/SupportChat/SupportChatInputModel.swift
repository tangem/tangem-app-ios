//
//  SupportChatInputModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct SupportChatInputModel {
    let environment: SupportChatEnvironment
    let cardId: String?
    let dataCollector: EmailDataCollector?

    init(
        environment: SupportChatEnvironment,
        cardId: String? = nil,
        dataCollector: EmailDataCollector? = nil
    ) {
        self.environment = environment
        self.cardId = cardId
        self.dataCollector = dataCollector
    }
}
