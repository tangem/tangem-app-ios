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
        walletModel.domainModel.isUserWalletLocked
    }

    // MARK: Published Properties

    @Published private(set) var walletIcon: LoadingValue<ImageValue> = .loading
    @Published private(set) var fiatBalanceState: LoadableTokenBalanceView.State = .loading()

    private var bag = Set<AnyCancellable>()

    init(walletModel: AccountSelectorWalletItem) {
        self.walletModel = walletModel

        bind()
        loadWalletImage()
    }

    func loadWalletImage() {
        runTask(in: self) { viewModel in
            let image = await viewModel.walletModel.walletImageProvider.loadSmallImage()

            viewModel.walletIcon = .loaded(image)
        }
    }
    
    private func bind() {
        if case .active(let wallet) = walletModel.wallet {
            wallet.account.fiatAvailableBalanceProvider.formattedBalanceTypePublisher
                .receiveOnMain()
                .withWeakCaptureOf(self)
                .sink { viewModel, balanceType in
                    viewModel.fiatBalanceState = LoadableTokenBalanceViewStateBuilder().build(type: balanceType)
                }
                .store(in: &bag)
        }
    }
}
