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
import SwiftUI
import ChatProvidersSDK
import AnswerBotProvidersSDK

class SupportChatViewModel {
    @Injected(\.keysManager) private var keysManager: KeysManager
    
    init() {
        Zendesk.initialize(appId: keysManager.zendesk.zendeskAppId,
                           clientId: keysManager.zendesk.zendeskClientId,
                           zendeskUrl: keysManager.zendesk.zendeskUrl)
        Support.initialize(withZendesk: Zendesk.instance)
        AnswerBot.initialize(withZendesk: Zendesk.instance, support: Support.instance!)
        let accountKey = Zendesk.instance?.accountDetails.accountUrl ?? ""
        Chat.initialize(accountKey: accountKey)
        if Chat.instance?.hasIdentity ?? false {
            print("identity")
        } else {
            print("no identity")
        }
    }
    
    func openChat() -> some View {
        return SupportChatView()
            .edgesIgnoringSafeArea([.bottom, .top])
    }
}
