//
//  WalletSelectorViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class WalletSelectorViewModel: ObservableObject {
    var itemViewModels: [WalletSelectorItemViewModel] = []

    private weak var dataSource: WalletSelectorDataSource?
    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(dataSource: WalletSelectorDataSource?) {
        self.dataSource = dataSource
        itemViewModels = dataSource?.walletSelectorItemViewModels ?? []

        bind()
    }

    func bind() {
        dataSource?.selectedUserWalletModelPublisher
            .sink { [weak self] userWalletModel in
                self?.itemViewModels.forEach { item in
                    item.isSelected = item.id == userWalletModel?.userWalletId
                }
            }
            .store(in: &bag)
    }
}
