//
//  SwappingSuccessCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class SwappingSuccessCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: ExpressSuccessSentViewModel?

    // MARK: - Child view models

    @Published var webViewContainerViewModel: WebViewContainerViewModel?

    required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        switch options {
        case .express(let factory, let data):
            rootViewModel = factory.makeExpressSuccessSentViewModel(data: data, coordinator: self)
        }
    }
}

// MARK: - Options

extension SwappingSuccessCoordinator {
    enum Options {
        case express(factory: ExpressModulesFactory, SentExpressTransactionData)
    }
}

// MARK: - ExpressSuccessSentRoutable

extension SwappingSuccessCoordinator: ExpressSuccessSentRoutable {
    func openWebView(url: URL?, title: String) {
        webViewContainerViewModel = WebViewContainerViewModel(url: url, title: title, withCloseButton: true)
    }

    func close() {
        dismiss()
    }
}
