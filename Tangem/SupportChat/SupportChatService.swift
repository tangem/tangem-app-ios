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

class SupportChatService {
    @Injected(\.keysManager) private var keysManager: KeysManager

    init() {
        Zendesk.initialize(appId: keysManager.zendesk.zendeskAppId,
                           clientId: keysManager.zendesk.zendeskClientId,
                           zendeskUrl: keysManager.zendesk.zendeskUrl)
        Support.initialize(withZendesk: Zendesk.instance)
        Zendesk.instance?.setIdentity(Identity.createAnonymous())
    }

    func chatView() -> some View {
        return SupportChatView()
            .edgesIgnoringSafeArea(.vertical)
    }
}
