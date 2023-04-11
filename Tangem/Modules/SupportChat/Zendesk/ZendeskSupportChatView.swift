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
        coordinator.viewModel.setNeedDisplayError = coordinator.setNeedDisplay(error:)
        coordinator.viewModel.chatDidLoadState = coordinator.setNeedUpdateBar(state:)

        return coordinator
    }

    // MARK: - Coordinator

    final class Coordinator: UINavigationController {
        weak var viewModel: ZendeskSupportChatViewModel!

        @objc
        func leftBarButtonItemDidTouch(_ sender: UIBarButtonItem) {
            let alertController = UIAlertController(title: "Выберите действие", message: nil, preferredStyle: .actionSheet)

            alertController.addAction(
                .init(title: "Отправить логи", style: .default, handler: { _ in
                    self.viewModel.sendLogFileIntoChat()
                })
            )

            alertController.addAction(
                .init(title: "Оценить оператора", style: .default, handler: { _ in
                    self.userRateButtonDidTouch()
                })
            )

            alertController.addAction(.init(title: "Cancel", style: .cancel))

            present(alertController, animated: true)
        }

        @objc
        func userRateButtonDidTouch() {
            let alertController = UIAlertController(title: "Оцените оператора", message: nil, preferredStyle: .actionSheet)

            alertController.addAction(
                .init(title: "Нравится", style: .default, handler: { _ in
                    self.viewModel.rateUser(isPositive: true)
                })
            )

            alertController.addAction(
                .init(title: "Не нравится", style: .default, handler: { _ in
                    self.viewModel.rateUser(isPositive: false)
                })
            )

            alertController.addAction(.init(title: "Cancel", style: .cancel))

            present(alertController, animated: true)
        }

        func setNeedDisplay(error: ZendeskSupportChatViewModel.DisplayError) {
            let alertController = UIAlertController(title: "", message: nil, preferredStyle: .alert)
            alertController.addAction(.init(title: "Cancel", style: .cancel))
            present(alertController, animated: true)
        }

        func setNeedUpdateBar(state: Bool) {
            if state {
                viewControllers.first?.navigationItem.setLeftBarButton(
                    UIBarButtonItem(
                        image: Assets.compass.uiImage,
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
