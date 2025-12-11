//
//  ReferralCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import BlockchainSdk

class ReferralCoordinator: CoordinatorObject {
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: FloatingSheetPresenter

    var dismissAction: Action<Void>
    var popToRootAction: Action<PopToRootOptions>

    @Published var referralViewModel: ReferralViewModel? = nil
    @Published var tosViewModel: WebViewContainerViewModel? = nil

    required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        referralViewModel = .init(input: options.input, coordinator: self)
    }

    @MainActor
    func closeSheet() {
        floatingSheetPresenter.removeActiveSheet()
    }
}

extension ReferralCoordinator {
    struct Options {
        let input: ReferralInputModel
    }
}

extension ReferralCoordinator: ReferralRoutable {
    func openTOS(with url: URL) {
        tosViewModel = WebViewContainerViewModel(
            url: url,
            title: Localization.detailsReferralTitle
        )
    }

    func showAccountSelector(
        selectedAccount: any BaseAccountModel,
        userWalletModel: UserWalletModel,
        cryptoAccountModelsFilter: @escaping (any CryptoAccountModel) -> Bool,
        onSelect: @escaping (any CryptoAccountModel) -> Void
    ) {
        Task { @MainActor in
            floatingSheetPresenter.enqueue(
                sheet: AccountSelectorViewModel(
                    selectedItem: selectedAccount,
                    userWalletModel: userWalletModel,
                    cryptoAccountModelsFilter: cryptoAccountModelsFilter,
                    onSelect: { [weak self] result in
                        onSelect(result.cryptoAccountModel)
                        self?.closeSheet()
                    }
                )
            )
        }
    }
}
