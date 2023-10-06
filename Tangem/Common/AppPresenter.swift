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
        Analytics.log(.chatScreenOpened)
        if FeatureProvider.isAvailable(.sprinklr) {
            let viewModel = SupportChatViewModel(input: input)
            let view = SupportChatView(viewModel: viewModel)
            let controller = UIHostingController(rootView: view)
            show(controller)
        } else {
            SprinklrManager.showSupportScreen()
        }
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
