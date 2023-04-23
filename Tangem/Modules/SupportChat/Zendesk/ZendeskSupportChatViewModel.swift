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

    private var chatViewController: UIViewController?
    private var observationToken: ChatProvidersSDK.ObservationToken?

    private var showSupportChatSheet: ((ActionSheet) -> Void)?

    init(
        cardId: String? = nil,
        dataCollector: EmailDataCollector? = nil,
        showSupportChatSheet: ((ActionSheet) -> Void)?
    ) {
        self.cardId = cardId
        self.dataCollector = dataCollector
        self.showSupportChatSheet = showSupportChatSheet

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
                self.chatViewController?.navigationItem.setLeftBarButton(
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

        Chat.instance?
            .providers
            .profileProvider
            .setNote("\(device) \(cardId ?? "")")

        let chatEngine = try ChatEngine.engine()
        chatViewController = try Messaging.instance.buildUI(engines: [chatEngine], configs: [chatConfiguration, messagingConfiguration])

        return chatViewController ?? UIViewController()
    }

    // MARK: - Private Implementation

    private func sendLogFileIntoChat() {
        dataCollector?.attachmentUrls { attachments in
            attachments.forEach {
                guard let attachmentUrl = $0.url else { return }
                Chat.chatProvider?.sendFile(url: attachmentUrl)
            }
        }
    }

    private func sendRateUser(_ isPositive: Bool) {
        Chat.chatProvider?.sendChatRating(isPositive ? .good : .bad)
    }

    private func makeActionSheetChatUserMenuActions() -> ActionSheet {
        let buttonCancel: ActionSheet.Button = .default(Text(Localization.commonCancel))
        let buttonSendLog: ActionSheet.Button = .default(Text(Localization.chatUserActionSendLog), action: sendLogFileIntoChat)
        let buttonRateOperator: ActionSheet.Button = .default(Text(Localization.chatUserActionRateUser), action: { [unowned self] in
            self.showSupportChatSheet?(self.makeActionSheetChatRateOperatorActions())
        })

        let sheet = ActionSheet(
            title: Text(Localization.chatUserActionsTitle),
            buttons: [buttonSendLog, buttonRateOperator, buttonCancel]
        )

        return sheet
    }

    private func makeActionSheetChatRateOperatorActions() -> ActionSheet {
        let buttonCancel: ActionSheet.Button = .default(Text(Localization.commonCancel))
        let buttonLike: ActionSheet.Button = .default(Text(Localization.commonLike), action: { [unowned self] in
            self.sendRateUser(true)
        })
        let buttonDislike: ActionSheet.Button = .default(Text(Localization.commonDislike), action: { [unowned self] in
            self.sendRateUser(false)
        })

        let sheet = ActionSheet(
            title: Text(Localization.chatUserRateOperatorTitle),
            buttons: [buttonLike, buttonDislike, buttonCancel]
        )

        return sheet
    }

    @objc
    func leftBarButtonItemDidTouch(_ sender: UIBarButtonItem) {
        showSupportChatSheet?(makeActionSheetChatUserMenuActions())
    }
}
