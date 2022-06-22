//
//  ChatView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import ZendeskCoreSDK
import MessagingSDK
import SupportSDK
import ChatSDK
import AnswerBotSDK
import SwiftUI

struct SupportChatView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> some UIViewController {
        let ident = Identity.createAnonymous()
        Zendesk.instance?.setIdentity(ident)
        do {
            return try UINavigationController(rootViewController: buildUI())
        } catch {
            return UINavigationController(rootViewController: UIViewController(nibName: nil, bundle: nil))
        }
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) { }
    
    func buildUI() throws -> UIViewController {
        let messagingConfiguration = MessagingConfiguration()
        messagingConfiguration.name = "Tangem"
        let supportEngine = try SupportEngine.engine()
        let chatEngine = try ChatEngine.engine()
        return try Messaging.instance.buildUI(engines: [supportEngine, chatEngine],
                                              configs: [messagingConfiguration])
    }
}
