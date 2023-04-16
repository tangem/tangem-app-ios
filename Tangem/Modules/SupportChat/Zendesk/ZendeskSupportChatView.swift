//
//  ZendeskSupportChatView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import UIKit
import SwiftUI

struct ZendeskSupportChatView: UIViewControllerRepresentable {
    let viewModel: ZendeskSupportChatViewModel

    func makeUIViewController(context: Context) -> UIViewController {
        return context.coordinator
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        guard let viewController = try? viewModel.buildUI() else {
            return Coordinator(rootViewController: UIViewController(nibName: nil, bundle: nil))
        }

        let coordinator = Coordinator(rootViewController: viewController)
        coordinator.viewModel = viewModel
        coordinator.viewModel.chatDidLoadState = coordinator.setNeedUpdateBar(state:)

        return coordinator
    }

    // MARK: - Coordinator

    final class Coordinator: UINavigationController {
        weak var viewModel: ZendeskSupportChatViewModel!

        @objc
        func leftBarButtonItemDidTouch(_ sender: UIBarButtonItem) {
            let alertController = UIAlertController(title: Localization.chatUserActionsTitle, message: nil, preferredStyle: .actionSheet)

            alertController.addAction(.init(title: Localization.chatUserActionSendLog, style: .default) { _ in
                self.viewModel.sendLogFileIntoChat()
            })

            alertController.addAction(.init(title: Localization.chatUserActionRateUser, style: .default) { _ in
                self.userRateButtonDidTouch()
            })

            alertController.addAction(.init(title: Localization.commonCancel, style: .cancel))

            present(alertController, animated: true)
        }

        @objc
        func userRateButtonDidTouch() {
            let alertController = UIAlertController(title: Localization.chatUserRateOperatorTitle, message: nil, preferredStyle: .actionSheet)

            alertController.addAction(.init(title: Localization.commonLike, style: .default) { _ in
                self.viewModel.sendRateUser(isPositive: true)
            })

            alertController.addAction(.init(title: Localization.commonDislike, style: .default) { _ in
                self.viewModel.sendRateUser(isPositive: false)
            })

            alertController.addAction(.init(title: Localization.commonCancel, style: .cancel))

            present(alertController, animated: true)
        }

        func setNeedUpdateBar(state: Bool) {
            if state {
                viewControllers.first?.navigationItem.setLeftBarButton(
                    UIBarButtonItem(
                        image: Assets.chatSettings.uiImage,
                        style: .plain,
                        target: self,
                        action: #selector(Coordinator.leftBarButtonItemDidTouch(_:))
                    ),
                    animated: true
                )
            } else {
                viewControllers.first?.navigationItem.setLeftBarButtonItems([], animated: false)
            }
        }
    }
}
