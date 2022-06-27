//
//  SupportChatViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import ZendeskCoreSDK
import SupportSDK
import MessagingSDK

class SupportChatViewModel {
    let supportChatService: SupportChatServiceProtocol

    private let chatBotName: String = "Tangem"
    private var messagingConfiguration: MessagingConfiguration {
        let messagingConfiguration = MessagingConfiguration()
        messagingConfiguration.name = chatBotName
        return messagingConfiguration
    }

    init(supportChatService: SupportChatServiceProtocol) {
        self.supportChatService = supportChatService
    }

    func buildUI() throws -> UIViewController {
        let supportEngine = try SupportEngine.engine()
        return try Messaging.instance.buildUI(engines: [supportEngine],
                                              configs: [messagingConfiguration])
    }

}
