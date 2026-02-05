//
//  TangemPayWalletSelectorDataSource.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class TangemPayWalletSelectorDataSource: WalletSelectorDataSource {
    private let _selectedUserWalletModel: CurrentValueSubject<UserWalletModel?, Never> = .init(nil)

    var selectedUserWalletIdPublisher: AnyPublisher<UserWalletId?, Never> {
        _selectedUserWalletModel.map { $0?.userWalletId }.eraseToAnyPublisher()
    }

    let userWalletModels: [UserWalletModel]

    var itemViewModels: [WalletSelectorItemViewModel] {
        userWalletModels
            .map { userWalletModel in
                WalletSelectorItemViewModel(
                    userWalletId: userWalletModel.userWalletId,
                    cardSetLabel: userWalletModel.config.cardSetLabel,
                    isUserWalletLocked: userWalletModel.isUserWalletLocked,
                    infoProvider: userWalletModel,
                    totalBalancePublisher: userWalletModel.totalBalancePublisher,
                    isSelected: userWalletModel.userWalletId == _selectedUserWalletModel.value?.userWalletId
                ) { [weak self] userWalletId in
                    guard let self = self else { return }

                    let selectedUserWalletModel = userWalletModels[userWalletId]
                    _selectedUserWalletModel.send(selectedUserWalletModel)
                }
            }
    }

    private var cancellable: Cancellable?

    init(
        userWalletModels: [UserWalletModel],
        onSelect: @escaping (UserWalletModel) -> Void
    ) {
        self.userWalletModels = userWalletModels
        cancellable = _selectedUserWalletModel
            .compactMap { $0 }
            .first()
            .sink(receiveValue: onSelect)
    }
}
