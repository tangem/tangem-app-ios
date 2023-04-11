//
//  ZendeskSupportChatViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import ZendeskCoreSDK
import MessagingSDK
import ChatSDK
import ChatProvidersSDK
import SupportSDK
import Foundation
import SwiftUI
import UIKit
import DeviceGuru

final class ZendeskSupportChatViewModel: ObservableObject {
    @Injected(\.keysManager) private var keysManager: KeysManager

    let cardId: String?
    let dataCollector: EmailDataCollector?

    var setNeedDisplayError: ((DisplayError) -> Void)?
    var chatDidLoadState: ((Bool) -> Void)?

    init(
        cardId: String? = nil,
        dataCollector: EmailDataCollector? = nil
    ) {
        self.cardId = cardId
        self.dataCollector = dataCollector

        initialize()
    }

    private var messagingConfiguration: MessagingConfiguration {
        let messagingConfiguration = MessagingConfiguration()
        messagingConfiguration.name = "Tangem"
        return messagingConfiguration
    }

    private var chatConfiguration: ChatConfiguration {
        let config = ChatConfiguration()
        config.isAgentAvailabilityEnabled = true
        config.isOfflineFormEnabled = true
        config.preChatFormConfiguration = ChatFormConfiguration(name: .hidden, email: .hidden, phoneNumber: .hidden, department: .hidden)
        return config
    }

    private func initialize() {
        let config = keysManager.zendesk
        Zendesk.initialize(
            appId: config.zendeskAppId,
            clientId: config.zendeskClientId,
            zendeskUrl: config.zendeskUrl
        )

        Support.initialize(withZendesk: Zendesk.instance)

        if let cardId = cardId {
            Zendesk.instance?.setIdentity(Identity.createJwt(token: cardId))
        } else {
            Zendesk.instance?.setIdentity(Identity.createAnonymous())
        }

        Chat.initialize(accountKey: config.zendeskAccountKey, appId: config.zendeskAppId)

        let _ = Chat.chatProvider?.observeChatState { [weak self] state in
            self?.chatDidLoadState?(state.chatSessionStatus == .started)
        }
    }

    func buildUI() throws -> UIViewController {
        let device = DeviceGuru().hardwareDescription() ?? ""
        let userWalletData = dataCollector?.dataForEmail ?? ""

        Chat.instance?
            .providers
            .profileProvider
            .setNote("\(device) \(cardId ?? "") \(userWalletData)")

        let chatEngine = try ChatEngine.engine()
        let viewController = try Messaging.instance.buildUI(engines: [chatEngine], configs: [chatConfiguration, messagingConfiguration])
        return viewController
    }

    func sendLogFileIntoChat() {
        dataCollector?.attachmentUrls { [weak self] result in
            result.forEach {
                guard let attachmentUrl = $0 else { return }
                Chat.chatProvider?.sendFile(url: attachmentUrl, completion: { result in
                    switch result {
                    case .success:
                        break
                    case .failure:
                        self?.setNeedDisplayError?(.errorSendingFile)
                    }
                })
            }
        }
    }

    func sendRateUser(isPositive: Bool) {
        Chat.chatProvider?.sendChatRating(isPositive ? .good : .bad, completion: { [weak self] result in
            switch result {
            case .success:
                break
            case .failure:
                self?.setNeedDisplayError?(.errorSendingRate)
            }
        })
    }
}

extension ZendeskSupportChatViewModel {
    enum DisplayError: Error {
        case errorSendingFile
        case errorSendingRate
    }
}
