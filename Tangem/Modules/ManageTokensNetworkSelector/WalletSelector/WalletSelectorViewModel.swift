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

        bind()
        fillItemViewModels()
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

    private func fillItemViewModels() {
        itemViewModels = dataSource?.userWalletModels.map { userWalletModel in
            WalletSelectorItemViewModel(
                userWalletModel: userWalletModel,
                isSelected: userWalletModel.userWalletId == dataSource?.selectedUserWalletModelPublisher.value?.userWalletId,
                cardImageProvider: CardImageProvider()
            ) { [weak self] userWalletId in
                let selectedUserWalletModel = self?.dataSource?.userWalletModels.first(where: { $0.userWalletId == userWalletId })
                self?.dataSource?.selectedUserWalletModelPublisher.send(selectedUserWalletModel)
            }
        } ?? []
    }
}
