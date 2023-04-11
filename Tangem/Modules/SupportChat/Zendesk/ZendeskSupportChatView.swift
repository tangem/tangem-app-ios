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

        viewController.navigationItem.setLeftBarButton(
            UIBarButtonItem(
                image: Assets.compass.uiImage,
                style: .plain,
                target: coordinator,
                action: #selector(Coordinator.leftBarButtonItemDidTouch(_:))
            ),
            animated: true
        )

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
                .init(title: "Оценить пользователя", style: .default, handler: { _ in
                    self.userRateButtonDidTouch()
                })
            )

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
                .init(title: "Не нравится", style: .destructive, handler: { _ in
                    self.viewModel.rateUser(isPositive: false)
                })
            )

            present(alertController, animated: true)
        }
    }
}
