//
//  SprinklrSupportChatView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import UIKit
import SwiftUI
import SPRMessengerClient

struct SprinklrSupportChatView: UIViewControllerRepresentable {
    let viewModel: SprinklrSupportChatViewModel

    func makeUIViewController(context: Context) -> UIViewController {
        guard let viewController = SPRMessengerViewController() else {
            AppLog.shared.debug("Failed to show Sprinklr screen")
            return UINavigationController(rootViewController: UIViewController(nibName: nil, bundle: nil))
        }
        viewController.modalPresentationStyle = .fullScreen // Sprinklr doesn't work as a sheet as of Oct 2023
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}
