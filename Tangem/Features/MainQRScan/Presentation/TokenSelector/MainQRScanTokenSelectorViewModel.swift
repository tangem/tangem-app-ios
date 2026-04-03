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
    let tokenSelectorViewModel: TokenSelectorViewModel

    private let sendParameters: PredefinedSendParameters
    private let accountsModeSingleAccountHeaders: [ObjectIdentifier: TokenSelectorAccountViewModel.HeaderType]
    private weak var coordinator: MainQRScanTokenSelectorRoutable?

    init(
        tokenSelectorViewModel: TokenSelectorViewModel,
        sendParameters: PredefinedSendParameters,
        accountsModeSingleAccountHeaders: [ObjectIdentifier: TokenSelectorAccountViewModel.HeaderType],
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
        for wallet: TokenSelectorWalletItemViewModel
    ) -> TokenSelectorAccountViewModel.HeaderType? {
        accountsModeSingleAccountHeaders[wallet.id]
    }
}

// MARK: - TokenSelectorViewModelOutput

extension MainQRScanTokenSelectorViewModel: TokenSelectorViewModelOutput {
    func userDidSelect(item: TokenSelectorItem) {
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
