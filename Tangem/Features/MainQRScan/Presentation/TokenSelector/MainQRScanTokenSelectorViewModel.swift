//
//  MainQRScanTokenSelectorViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - MainQRScanTokenSelectorViewModel

final class MainQRScanTokenSelectorViewModel: ObservableObject, Identifiable {
    let tokenSelectorViewModel: AccountsAwareTokenSelectorViewModel

    private let sendParameters: PredefinedSendParameters
    private let accountsModeSingleAccountHeaders: [ObjectIdentifier: AccountsAwareTokenSelectorAccountViewModel.HeaderType]
    private weak var coordinator: MainQRScanTokenSelectorRoutable?

    init(
        tokenSelectorViewModel: AccountsAwareTokenSelectorViewModel,
        sendParameters: PredefinedSendParameters,
        accountsModeSingleAccountHeaders: [ObjectIdentifier: AccountsAwareTokenSelectorAccountViewModel.HeaderType],
        coordinator: MainQRScanTokenSelectorRoutable
    ) {
        self.tokenSelectorViewModel = tokenSelectorViewModel
        self.sendParameters = sendParameters
        self.accountsModeSingleAccountHeaders = accountsModeSingleAccountHeaders
        self.coordinator = coordinator

        tokenSelectorViewModel.setup(with: self)
    }

    @MainActor
    func close() {
        coordinator?.closeTokenSelector()
    }

    func accountsModeHeader(
        for wallet: AccountsAwareTokenSelectorWalletItemViewModel
    ) -> AccountsAwareTokenSelectorAccountViewModel.HeaderType? {
        accountsModeSingleAccountHeaders[wallet.id]
    }
}

// MARK: - AccountsAwareTokenSelectorViewModelOutput

extension MainQRScanTokenSelectorViewModel: AccountsAwareTokenSelectorViewModelOutput {
    func userDidSelect(item: AccountsAwareTokenSelectorItem) {
        guard let walletModel = item.kind.walletModel else {
            return
        }

        Task { @MainActor [weak self] in
            guard let self else { return }

            coordinator?.didSelectToken(
                walletModel: walletModel,
                userWalletInfo: item.userWalletInfo,
                sendParameters: sendParameters
            )
        }
    }
}
