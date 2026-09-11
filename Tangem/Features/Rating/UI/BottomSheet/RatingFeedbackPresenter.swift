//
//  RatingFeedbackPresenter.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

@MainActor
protocol RatingFeedbackPresenter: AnyObject {
    func present(_ viewModel: RatingFeedbackBottomSheetViewModel)
    func dismiss()
}

@MainActor
final class FloatingSheetRatingFeedbackPresenter: RatingFeedbackPresenter {
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter

    func present(_ viewModel: RatingFeedbackBottomSheetViewModel) {
        floatingSheetPresenter.enqueue(sheet: viewModel)
    }

    func dismiss() {
        floatingSheetPresenter.removeActiveSheet()
    }
}
