//
//  ChatViewModel.swift
//  Tangem
//
//  Created by Pavel Grechikhin on 15.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import ZendeskCoreSDK
import SupportSDK
import MessagingSDK
import ChatSDK
import ChatProvidersSDK

protocol SupportChatServiceProtocol: Initializable { }

class SupportChatService: SupportChatServiceProtocol {
    @Injected(\.keysManager) private var keysManager: KeysManager

    func initialize() {
        Zendesk.initialize(appId: keysManager.zendesk.zendeskAppId,
                           clientId: keysManager.zendesk.zendeskClientId,
                           zendeskUrl: keysManager.zendesk.zendeskUrl)
        Support.initialize(withZendesk: Zendesk.instance)
        Zendesk.instance?.setIdentity(Identity.createAnonymous())
        Chat.initialize(accountKey: keysManager.zendesk.zendeskAccountKey, appId: keysManager.zendesk.zendeskAppId)
    }
}

private struct KeysManagerKey: InjectionKey {
    static var currentValue: SupportChatServiceProtocol = SupportChatService()
}

extension InjectedValues {
    var supportChatService: SupportChatServiceProtocol {
        get { Self[KeysManagerKey.self] }
        set { Self[KeysManagerKey.self] = newValue }
    }
}
