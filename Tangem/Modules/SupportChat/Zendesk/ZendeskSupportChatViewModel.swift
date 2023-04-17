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

final class ZendeskSupportChatViewModel {
    @Injected(\.keysManager) private var keysManager: KeysManager

    let cardId: String?
    let dataCollector: EmailDataCollector?

//    var chatDidLoadState: ((Bool) -> Void)?

    private var chatViewController: UIViewController!
    private var observationToken: ChatProvidersSDK.ObservationToken?

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

        Zendesk.instance?.setIdentity(Identity.createAnonymous())

        Chat.initialize(accountKey: config.zendeskAccountKey, appId: config.zendeskAppId)

        observationToken = Chat.chatProvider?.observeChatState { [weak self] state in
            guard let self = self else { return }

            if state.chatSessionStatus == .started {
                self.chatViewController.navigationItem.setLeftBarButton(
                    UIBarButtonItem(
                        image: Assets.chatSettings.uiImage,
                        style: .plain,
                        target: self,
                        action: #selector(ZendeskSupportChatViewModel.leftBarButtonItemDidTouch(_:))
                    ),
                    animated: true
                )
            } else {
                self.chatViewController?.navigationItem.setLeftBarButtonItems([], animated: false)
            }
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
        chatViewController = try Messaging.instance.buildUI(engines: [chatEngine], configs: [chatConfiguration, messagingConfiguration])

        return chatViewController
    }

    func sendLogFileIntoChat() {
        dataCollector?.attachmentUrls { attachments in
            attachments.forEach {
                guard let attachmentUrl = $0.url else { return }
                Chat.chatProvider?.sendFile(url: attachmentUrl)
            }
        }
    }

    func sendRateUser(isPositive: Bool) {
        Chat.chatProvider?.sendChatRating(isPositive ? .good : .bad)
    }

    @objc
    func leftBarButtonItemDidTouch(_ sender: UIBarButtonItem) {
        AppPresenter.shared.showSupportChatMenuActions { [weak self] in
            self?.sendLogFileIntoChat()
        } rateOperatorAnswer: { [weak self] answer in
            self?.sendRateUser(isPositive: answer)
        }
    }
}
