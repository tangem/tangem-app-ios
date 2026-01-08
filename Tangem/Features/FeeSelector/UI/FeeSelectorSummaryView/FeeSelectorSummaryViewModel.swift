//
//  FeeSelectorSummaryViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

protocol FeeSelectorSummaryRoutable: AnyObject {
    func userDidRequestTokenSelector()
    func userDidRequestFeeSelector()

    func userDidTapConfirmButton()
}

final class FeeSelectorSummaryViewModel: ObservableObject {
    // Some views

    private let interactor: FeeSelectorInteractor

    private weak var router: FeeSelectorSummaryRoutable?

    init(interactor: FeeSelectorInteractor) {
        self.interactor = interactor
    }

    func setup(router: FeeSelectorSummaryRoutable?) {
        self.router = router
    }

    func userDidTapToken() {
        router?.userDidRequestTokenSelector()
    }

    func userDidTapFee() {
        router?.userDidRequestFeeSelector()
    }
}
