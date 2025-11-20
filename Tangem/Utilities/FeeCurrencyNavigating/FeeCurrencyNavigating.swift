//
//  FeeCurrencyNavigating.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct FeeCurrencyNavigatingDismissOption {
    let userWalletId: UserWalletId
    let feeTokenItem: TokenItem

    init(walletModel: any WalletModel) {
        userWalletId = walletModel.userWalletId
        feeTokenItem = walletModel.feeTokenItem
    }

    init(userWalletId: UserWalletId, feeTokenItem: TokenItem) {
        self.userWalletId = userWalletId
        self.feeTokenItem = feeTokenItem
    }
}

/// A helper that helps to perform the common navigation flow: open the `Token Details` screen for the fee currency.
protocol FeeCurrencyNavigating where Self: AnyObject, Self: CoordinatorObject {
    static var feeCurrencyNavigationDelay: TimeInterval { get }

    var tokenDetailsCoordinator: TokenDetailsCoordinator? { get set }

    func openFeeCurrency(for model: any WalletModel, userWalletModel: UserWalletModel)
}

// MARK: - Default implementation

extension FeeCurrencyNavigating {
    static var feeCurrencyNavigationDelay: TimeInterval { 0.6 }

    func proceedFeeCurrencyNavigatingDismissOption(option: FeeCurrencyNavigatingDismissOption?) {
        guard let feeCurrencyOption = option else {
            return
        }

        let result = try? WalletModelFinder.findWalletModel(
            userWalletId: feeCurrencyOption.userWalletId,
            tokenItem: feeCurrencyOption.feeTokenItem
        )

        guard let result else {
            AppLogger.error(error: "FeeCurrency doesn't found for \(feeCurrencyOption.feeTokenItem.name)")
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + Self.feeCurrencyNavigationDelay) { [weak self] in
            self?.openFeeCurrency(for: result.walletModel, userWalletModel: result.userWalletModel)
        }
    }

    func openFeeCurrency(for model: any WalletModel, userWalletModel: UserWalletModel) {
        let dismissAction: Action<Void> = { [weak self] _ in
            self?.tokenDetailsCoordinator = nil
        }

        let coordinator = TokenDetailsCoordinator(dismissAction: dismissAction)
        coordinator.start(with: .init(userWalletModel: userWalletModel, walletModel: model))

        tokenDetailsCoordinator = coordinator
    }
}
