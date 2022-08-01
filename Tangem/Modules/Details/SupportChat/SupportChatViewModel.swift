//
//  SupportChatViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import ZendeskCoreSDK
import MessagingSDK
import ChatSDK
import ChatProvidersSDK
import Foundation
import UIKit
import DeviceGuru

class SupportChatViewModel: Identifiable {
    let id: UUID = .init()
    let cardID: String

    init(cardID: String = "") {
        self.cardID = cardID
    }

    private let chatBotName: String = "Tangem"
    private var messagingConfiguration: MessagingConfiguration {
        let messagingConfiguration = MessagingConfiguration()
        messagingConfiguration.name = chatBotName
        return messagingConfiguration
    }

    private var chatConfiguration: ChatConfiguration {
        let config = ChatConfiguration()
        config.isAgentAvailabilityEnabled = true
        config.isOfflineFormEnabled = true
        config.preChatFormConfiguration = ChatFormConfiguration(name: .hidden, email: .hidden, phoneNumber: .hidden, department: .hidden)
        return config
    }

    func buildUI() throws -> UIViewController {
        let device = DeviceGuru().hardwareDescription() ?? ""
        Chat
            .instance?
            .providers
            .profileProvider
            .setNote("\(device) \(cardID)")
        let chatEngine = try! ChatEngine.engine()
        let viewController = try! Messaging.instance.buildUI(engines: [chatEngine], configs: [chatConfiguration, messagingConfiguration])
        return viewController
    }
}
