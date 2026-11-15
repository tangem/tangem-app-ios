//
//  UserWalletSelectorItemsStore.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import UIKit
import TangemAccounts
import TangemFoundation

@MainActor
final class UserWalletSelectorItemsStore {
    var onChange: () -> Void = {}

    private var balances: [UserWalletId: SelectorBalance] = [:]
    private var images: [UserWalletId: UIImage] = [:]
    private var trackedUserWalletIds: Set<UserWalletId> = []
    private var bag = Set<AnyCancellable>()

    func track(_ userWalletModels: [any UserWalletModel]) {
        for userWalletModel in userWalletModels where trackedUserWalletIds.insert(userWalletModel.userWalletId).inserted {
            bindBalance(of: userWalletModel)
            bindName(of: userWalletModel)
            loadImage(of: userWalletModel)
        }
    }

    func item(for userWalletModel: any UserWalletModel, availability: SelectorAvailability) -> UserWalletSelectorItem {
        UserWalletSelectorItem(
            id: userWalletModel.userWalletId,
            name: userWalletModel.name,
            image: images[userWalletModel.userWalletId],
            balance: balances[userWalletModel.userWalletId] ?? .loading(cached: nil),
            availability: availability
        )
    }
}

// MARK: - Private

private extension UserWalletSelectorItemsStore {
    func bindBalance(of userWalletModel: any UserWalletModel) {
        let userWalletId = userWalletModel.userWalletId

        userWalletModel.totalBalancePublisher
            .withAppCurrencyCode()
            .combineLatest(userWalletModel.accountModelsManager.accountModelsPublisher)
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { store, input in
                let ((state, currencyCode), _) = input
                store.balances[userWalletId] = SelectorBalanceBuilder.build(state: state, currencyCode: currencyCode)
                store.onChange()
            }
            .store(in: &bag)
    }

    func bindName(of userWalletModel: any UserWalletModel) {
        userWalletModel.updatePublisher
            .compactMap(\.newName)
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { store, _ in
                store.onChange()
            }
            .store(in: &bag)
    }

    func loadImage(of userWalletModel: any UserWalletModel) {
        let walletImageProvider = userWalletModel.walletImageProvider
        let userWalletId = userWalletModel.userWalletId

        Task { [weak self] in
            let image = await walletImageProvider.loadSmallUIImage()
            self?.images[userWalletId] = image
            self?.onChange()
        }
        .eraseToAnyCancellable()
        .store(in: &bag)
    }
}
