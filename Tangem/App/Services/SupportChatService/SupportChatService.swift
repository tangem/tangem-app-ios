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
import ChatSDK
import ChatProvidersSDK

protocol SupportChatServiceProtocol {
    func initialize(with env: SupportChatEnvironment)
}

// [REDACTED_TODO_COMMENT]
class SupportChatService: SupportChatServiceProtocol {
    @Injected(\.keysManager) private var keysManager: KeysManager

    func initialize(with env: SupportChatEnvironment) {
        let config = keysManager.zendesk
        Zendesk.initialize(
            appId: config.zendeskAppId,
            clientId: config.zendeskClientId,
            zendeskUrl: config.zendeskUrl
        )
        Support.initialize(withZendesk: Zendesk.instance)
        Zendesk.instance?.setIdentity(Identity.createAnonymous())
        Chat.initialize(accountKey: config.zendeskAccountKey, appId: config.zendeskAppId)
    }
}

enum SupportChatEnvironment {
    case tangem
    case saltPay
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
