//
//  AppPresenter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

class AppPresenter {
    static let shared = AppPresenter()

    private init() {}

    func showSupportChat(input: SupportChatInputModel) {
        let viewModel = SupportChatViewModel(input: input)
        let view = SupportChatView(viewModel: viewModel)
        let controller = UIHostingController(rootView: view)
        Analytics.log(.chatScreenOpened)
        show(controller)
    }

    func showSupportChatMenuActions(
        sendLog: @escaping () -> Void,
        rateOperatorAnswer: @escaping (Bool) -> Void
    ) {
        let alertController = UIAlertController(title: Localization.chatUserActionsTitle, message: nil, preferredStyle: .actionSheet)

        alertController.addAction(.init(title: Localization.chatUserActionSendLog, style: .default) { _ in
            sendLog()
        })

        alertController.addAction(.init(title: Localization.chatUserActionRateUser, style: .default) { [weak self] _ in
            self?.showSupportChatRateChatOperator(answer: rateOperatorAnswer)
        })

        alertController.addAction(.init(title: Localization.commonCancel, style: .cancel))

        show(alertController)
    }

    func showSupportChatRateChatOperator(answer completion: @escaping (Bool) -> Void) {
        let alertController = UIAlertController(title: Localization.chatUserRateOperatorTitle, message: nil, preferredStyle: .actionSheet)

        alertController.addAction(.init(title: Localization.commonLike, style: .default) { _ in
            completion(true)
        })

        alertController.addAction(.init(title: Localization.commonDislike, style: .default) { _ in
            completion(false)
        })

        alertController.addAction(.init(title: Localization.commonCancel, style: .cancel))

        show(alertController)
    }

    func showError(_ error: Error) {
        show(error.alertController)
    }

    func show(_ controller: UIViewController, delay: TimeInterval = 0.3) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            UIApplication.modalFromTop(controller)
        }
    }
}
