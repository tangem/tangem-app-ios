//
//  AccountSelectorWalletCellViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

@MainActor
final class AccountSelectorWalletCellViewModel: ObservableObject {
    // MARK: Public Properties

    let walletModel: AccountSelectorWalletItem

    var isLocked: Bool {
        if case .locked = walletModel.wallet {
            return true
        }

        return false
    }

    // MARK: Published Properties

    @Published private(set) var walletIcon: LoadingResult<ImageValue, Never> = .loading
    @Published private(set) var fiatBalanceState: LoadableTokenBalanceView.State = .loading()

    // MARK: Private Properties

    private var bag = Set<AnyCancellable>()

    init(walletModel: AccountSelectorWalletItem) {
        self.walletModel = walletModel

        bind()
    }

    // MARK: Public Methods

    func loadWalletImage() async {
        let image = await walletModel.walletImageProvider.loadSmallImage()

        walletIcon = .success(image)
    }

    // MARK: Private Methods

    private func bind() {
        if case .active(let wallet) = walletModel.wallet {
            wallet.formattedBalanceTypePublisher
                .withWeakCaptureOf(self)
                .sink { viewModel, balanceState in
                    viewModel.fiatBalanceState = balanceState
                }
                .store(in: &bag)
        }
    }
}
