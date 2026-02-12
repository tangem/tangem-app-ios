//
//  MarketsTokensNetworkDataSource.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

class MarketsWalletDataProvider {
    // MARK: - Injected

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    // MARK: - Properties

    private let _userWalletModels: CurrentValueSubject<[UserWalletModel], Never> = .init([])
    private let _selectedUserWalletModel: CurrentValueSubject<UserWalletModel?, Never> = .init(nil)

    var selectedUserWalletModel: UserWalletModel? { _selectedUserWalletModel.value }

    var isWalletSelectorAvailable: Bool {
        userWalletRepository.models.filter { !$0.isUserWalletLocked && $0.config.hasFeature(.multiCurrency) }.count > 1
    }

    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init() {
        setupUserWalletModels()
        bind()
    }

    private func setupUserWalletModels() {
        let userWalletModels = userWalletRepository.models.filter { !$0.isUserWalletLocked }

        _userWalletModels.send(userWalletModels)

        if _selectedUserWalletModel.value == nil {
            let multiCurrencyWallets = userWalletModels.filter { $0.config.hasFeature(.multiCurrency) }
            let selectedUserWalletModel = multiCurrencyWallets
                .first { userWalletModel in
                    userWalletModel.userWalletId == userWalletRepository.selectedModel?.userWalletId
                } ?? multiCurrencyWallets.first

            _selectedUserWalletModel.send(selectedUserWalletModel)
        }
    }

    private func clearUserWalletModels() {
        _userWalletModels.send([])
        _selectedUserWalletModel.send(nil)
    }

    private func bind() {
        userWalletRepository.eventProvider
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink(receiveValue: { dataProvider, event in
                switch event {
                case .unlocked:
                    break
                case .locked:
                    dataProvider.clearUserWalletModels()
                case .inserted, .unlockedWallet:
                    dataProvider.setupUserWalletModels()
                case .deleted(let userWalletIds, let isEmpty):
                    if isEmpty {
                        return
                    }

                    if let selectedUserWalletModel = dataProvider.selectedUserWalletModel, userWalletIds.contains(where: { $0 == selectedUserWalletModel.userWalletId }) {
                        dataProvider._selectedUserWalletModel.send(nil)
                    }
                    dataProvider.setupUserWalletModels()
                case .selected(let userWalletId):
                    if let selectedUserWalletModel = dataProvider.selectedUserWalletModel, selectedUserWalletModel.userWalletId == userWalletId {
                        return
                    }

                    guard
                        let selectedUserWalletModel = dataProvider.userWalletRepository.selectedModel,
                        selectedUserWalletModel.config.hasFeature(.multiCurrency)
                    else {
                        return
                    }

                    dataProvider._selectedUserWalletModel.send(selectedUserWalletModel)
                case .reordered:
                    break
                }
            })
            .store(in: &bag)
    }
}

extension MarketsWalletDataProvider {
    var userWalletModels: [UserWalletModel] { _userWalletModels.value }

    var userWalletModelsPublisher: AnyPublisher<[UserWalletModel], Never> {
        _userWalletModels.eraseToAnyPublisher()
    }
}

extension MarketsWalletDataProvider: WalletSelectorDataSource {
    var selectedUserWalletIdPublisher: AnyPublisher<UserWalletId?, Never> {
        _selectedUserWalletModel.map { $0?.userWalletId }.eraseToAnyPublisher()
    }

    var selectedUserWalletModelPublisher: AnyPublisher<UserWalletId?, Never> {
        _selectedUserWalletModel.map { $0?.userWalletId }.eraseToAnyPublisher()
    }

    var itemViewModels: [WalletSelectorItemViewModel] {
        userWalletModels
            .filter { $0.config.hasFeature(.multiCurrency) }
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
}
