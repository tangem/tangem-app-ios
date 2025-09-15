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
            walletModel: options.walletModel,
            apy: options.apy,
            lastYearReturns: options.lastYearReturns,
            networkFee: options.networkFee,
            maximumFee: options.maximumFee,
            coordinator: self
        )
    }
}

// MARK: - Options

extension YieldModulePromoCoordinator {
    struct Options {
        let walletModel: any WalletModel
        let apy: String
        let networkFee: Decimal
        let maximumFee: Decimal
        let lastYearReturns: [String: Double]
    }
}
