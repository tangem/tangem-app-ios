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
        let controller: UIViewController
        if let sprinklrViewModel = viewModel.sprinklrViewModel {
            let sprinklrView = SprinklrSupportChatView(viewModel: sprinklrViewModel)
            controller = sprinklrView.viewController
        } else {
            let view = SupportChatView(viewModel: viewModel)
            controller = UIHostingController(rootView: view)
        }

        Analytics.log(.chatScreenOpened)
        show(controller)
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
