//
//  YieldModulePromoCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

final class YieldModulePromoCoordinator: CoordinatorObject {
    // MARK: - Injected

    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter

    // MARK: - Propeties

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    @Published var rootViewModel: YieldModulePromoViewModel? = nil

    // MARK: - Init

    required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    // MARK: - Public Implementation

    func start(with options: Options) {
        rootViewModel = .init(
            tokenName: options.tokenName,
            annualYield: options.annualYield.formatted(),
            lastYearReturns: options.lastYearReturns,
            tokenImage: options.tokenImage,
            networkFee: options.currentFee,
            maximumFee: options.maxFee,
            blockchainName: options.blockchainName,
            coordinator: self
        )
    }

    func openRateInfoSheet(params: YieldPromoBottomSheetViewModel.RateInfoParams) {
        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: YieldPromoBottomSheetViewModel(flow: .rateInfo(params: params)))
        }
    }

    func openStartEarningSheet(params: YieldPromoBottomSheetViewModel.StartEarningParams) {
        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: YieldPromoBottomSheetViewModel(flow: .startYearing(params: params)))
        }
    }
}

// MARK: - Options

extension YieldModulePromoCoordinator {
    struct Options {
        let tokenName: String
        let startEarningAction: () -> Void
        let annualYield: Double
        let currentFee: Double
        let maxFee: Double
        let blockchainName: String
        let lastYearReturns: [String: Double]
        let tokenImage: Image
    }
}
