//
//  SupportChatViewModel.swift
//  Tangem
//
//  Created by Pavel Grechikhin on 27.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import ZendeskCoreSDK
import SupportSDK
import MessagingSDK
import ChatSDK
import Foundation
import UIKit

class SupportChatViewModel: Identifiable {
    let id: UUID = .init()

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
        return config
    }

    func buildUI() throws -> UIViewController {
        let chatEngine = try! ChatEngine.engine()
        let viewController = try! Messaging.instance.buildUI(engines: [chatEngine], configs: [chatConfiguration, messagingConfiguration])
        return viewController
    }
}
