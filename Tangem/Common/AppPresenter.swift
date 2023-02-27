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
    @Injected(\.keysManager) private var keysManager: KeysManager

    static let shared = AppPresenter()

    private init() {}

    func showSprinklChat() {
        let viewModel = WebViewContainerViewModel.sprinklSupportChat(appID: keysManager.saltPay.sprinklrAppID)
        let view = WebViewContainer(viewModel: viewModel)
        let controller = UIHostingController(rootView: view)
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
