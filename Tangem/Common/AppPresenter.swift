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

    func showChat(cardId: String? = nil, dataCollector: EmailDataCollector? = nil) {
        let viewModel = SupportChatViewModel(cardId: cardId, dataCollector: dataCollector)
        let view = SupportChatView(viewModel: viewModel)
        let controller = UIHostingController(rootView: view)
        show(controller)
    }

    private func show(_ controller: UIViewController) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            UIApplication.modalFromTop(controller)
        }
    }
}
