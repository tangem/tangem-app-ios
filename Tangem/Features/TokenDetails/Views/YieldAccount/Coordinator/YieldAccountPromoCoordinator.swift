//
//  YieldAccountPromoCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

final class YieldAccountPromoCoordinator: CoordinatorObject {
    // MARK: - Injected

    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter

    // MARK: - Propeties

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    @Published var rootViewModel: YieldAccountPromoViewModel? = nil

    // MARK: - Init

    required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    // MARK: - Public Implementation

    func start(with options: Options) {
        rootViewModel = .init(
            annualYield: options.annualYield.formatted(),
            lastYearReturns: options.lastYearReturns,
            coordinator: self
        )
    }

    func openInterestRateInfo(lastYearReturns: [String: Double]) {
        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: YieldInterestRateSheetViewModel(lastYearReturns: lastYearReturns))
        }
    }

    func showStartEarningSheet() {}
}

// MARK: - Options

extension YieldAccountPromoCoordinator {
    struct Options {
        let startEarningAction: () -> Void
        let annualYield: Double
        let currentFee: Double
        let maxFee: Double
        let networkName: String
        let lastYearReturns: [String: Double]
    }
}
