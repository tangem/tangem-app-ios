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
import CombineExt
import TangemUI

@MainActor
final class AccountSelectorWalletCellViewModel: ObservableObject {
    // MARK: Public Properties

    let walletModel: AccountSelectorWalletItem

    var isDisabled: Bool {
        isLocked || isUnavailable
    }

    // MARK: Published Properties

    @Published private(set) var walletIcon: LoadingResult<ImageValue, Never> = .loading
    @Published private(set) var fiatBalanceState: LoadableBalanceView.State = .loading()

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
                .receiveOnMain()
                .assign(to: \.fiatBalanceState, on: self, ownership: .weak)
                .store(in: &bag)
        }
    }

    private var isUnavailable: Bool {
        walletModel.accountAvailability != .available
    }

    private var isLocked: Bool {
        walletModel.wallet.isLocked
    }
}
