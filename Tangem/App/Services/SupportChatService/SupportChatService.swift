//
//  ChatViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import ZendeskCoreSDK
import SupportSDK
import MessagingSDK

protocol SupportChatServiceProtocol { }

class SupportChatService: SupportChatServiceProtocol {
    @Injected(\.keysManager) private var keysManager: KeysManager

    init() {
        Zendesk.initialize(appId: keysManager.zendesk.zendeskAppId,
                           clientId: keysManager.zendesk.zendeskClientId,
                           zendeskUrl: keysManager.zendesk.zendeskUrl)
        Support.initialize(withZendesk: Zendesk.instance)
        Zendesk.instance?.setIdentity(Identity.createAnonymous())
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
