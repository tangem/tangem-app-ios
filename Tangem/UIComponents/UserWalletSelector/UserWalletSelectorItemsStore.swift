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
import TangemUI

@MainActor
final class UserWalletSelectorItemsStore {
    var onChange: () -> Void = {}

    private var balances: [UserWalletId: SelectorBalance] = [:]
    private var icons: [UserWalletId: WalletIconContent] = [:]
    private var trackedUserWalletIds: Set<UserWalletId> = []
    private var bag = Set<AnyCancellable>()

    func track(_ userWalletModels: [any UserWalletModel]) {
        for userWalletModel in userWalletModels where trackedUserWalletIds.insert(userWalletModel.userWalletId).inserted {
            bindBalance(of: userWalletModel)
            bindName(of: userWalletModel)
            loadIcon(of: userWalletModel)
        }
    }

    func item(for userWalletModel: any UserWalletModel, availability: SelectorAvailability) -> UserWalletSelectorItem {
        UserWalletSelectorItem(
            id: userWalletModel.userWalletId,
            name: userWalletModel.name,
            icon: icons[userWalletModel.userWalletId],
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

    func loadIcon(of userWalletModel: any UserWalletModel) {
        let userWalletId = userWalletModel.userWalletId

        switch userWalletModel.walletIcon {
        case .content(let content):
            icons[userWalletId] = content

        case .loadable(let imageProvider):
            Task { [weak self] in
                let image = await imageProvider.loadSmallUIImage()
                self?.icons[userWalletId] = .image(image)
                self?.onChange()
            }
            .eraseToAnyCancellable()
            .store(in: &bag)
        }
    }
}
