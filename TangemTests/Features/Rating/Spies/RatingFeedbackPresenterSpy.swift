//
//  RatingFeedbackPresenterSpy.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
@testable import Tangem

@MainActor
final class RatingFeedbackPresenterSpy: RatingFeedbackPresenter {
    private(set) var presented: [RatingFeedbackBottomSheetViewModel] = []
    private(set) var dismissCallsCount = 0

    func present(_ viewModel: RatingFeedbackBottomSheetViewModel) {
        presented.append(viewModel)
    }

    func dismiss() {
        dismissCallsCount += 1
    }
}
