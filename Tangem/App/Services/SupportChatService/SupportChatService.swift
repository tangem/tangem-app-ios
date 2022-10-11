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

class SupportChatService: SupportChatServiceProtocol {
    @Injected(\.keysManager) private var keysManager: KeysManager

    func initialize(with env: SupportChatEnvironment) {
        let config = makeConfig(for: env)
        Zendesk.initialize(appId: config.zendeskAppId,
                           clientId: config.zendeskClientId,
                           zendeskUrl: config.zendeskUrl)
        Support.initialize(withZendesk: Zendesk.instance)
        Zendesk.instance?.setIdentity(Identity.createAnonymous())
        Chat.initialize(accountKey: config.zendeskAccountKey, appId: config.zendeskAppId)
    }

    private func makeConfig(for env: SupportChatEnvironment) -> ZendeskConfig {
        switch env {
        case .default:
            return keysManager.zendesk
        case .saltpay:
            return keysManager.saltPay.zendesk
        }
    }
}

enum SupportChatEnvironment {
    case `default`
    case saltpay
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
