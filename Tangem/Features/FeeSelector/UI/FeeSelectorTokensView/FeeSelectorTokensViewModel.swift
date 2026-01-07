//
//  FeeSelectorTokensViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

protocol FeeSelectorTokensRoutable: AnyObject {
    func userDidSelectFeeToken()
}

final class FeeSelectorTokensViewModel: ObservableObject {
    // Some views

    private let interactor: FeeSelectorInteractor

    private weak var router: FeeSelectorTokensRoutable?

    init(interactor: FeeSelectorInteractor) {
        self.interactor = interactor
    }

    func setup(router: FeeSelectorTokensRoutable?) {
        self.router = router
    }

    func userDidSelectFeeToken() {
        router?.userDidSelectFeeToken()
    }
}
