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

class SupportChatViewModel {
    init() {
        Zendesk.initialize(appId: "", clientId: "", zendeskUrl: "")
        Support.initialize(withZendesk: Zendesk.instance)
    }
    
    func openChat() -> some View {
        return SupportChatView()
    }
}
