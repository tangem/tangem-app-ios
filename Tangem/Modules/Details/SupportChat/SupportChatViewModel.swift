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
import Foundation

class SupportChatViewModel: Identifiable {
    let id: UUID = .init()

    private let chatBotName: String = "Tangem"
    private var messagingConfiguration: MessagingConfiguration {
        let messagingConfiguration = MessagingConfiguration()
        messagingConfiguration.name = chatBotName
        return messagingConfiguration
    }

    func buildUI() throws -> UIViewController {
        let requestConfig = RequestUiConfiguration()
        return RequestUi.buildRequestList(with: [requestConfig])
    }
}
