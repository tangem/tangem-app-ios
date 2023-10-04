//
//  ManageTokensViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

final class ManageTokensViewModel: ObservableObject {
    // MARK: - Injected & Published Properties

    @Injected(\.tokenQuotesRepository) private var tokenQuotesRepository: TokenQuotesRepository
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    // I can't use @Published here, because of swiftui redraw perfomance drop
    var enteredSearchText = CurrentValueSubject<String, Never>("")

    @Published var tokenViewModels: [ManageTokensItemViewModel] = []
    @Published var isLoading: Bool = true
    @Published var hasPendingDerivations: Bool = false

    // MARK: - Properties

    var hasNextPage: Bool {
        loader.canFetchMore
    }

    var pendingDerivationOptions: GenerateAddressesView.Options {
        .init(
            numberOfNetworks: derivationManagers.map { $0.value }.reduce(0, +),
            currentWalletNumber: (userWalletRepository.selectedIndexUserWalletModel ?? 0) + 1,
            totalWalletNumber: userWalletRepository.userWallets.count
        )
    }

    private unowned let coordinator: ManageTokensRoutable

    private lazy var loader = setupListDataLoader()
    private let percentFormatter = PercentFormatter()
    private let balanceFormatter = BalanceFormatter()
    private var bag = Set<AnyCancellable>()
    private var cacheExistTokenUserList: [TokenItem] = []

    private var derivationManagers: [UserWalletId: Int] = [:] {
        didSet {
            hasPendingDerivations = !derivationManagers.filter { $0.value > 0 }.isEmpty
        }
    }

    // MARK: - Init

    init(coordinator: ManageTokensRoutable) {
        self.coordinator = coordinator

        bind()
        updateAlreadyExistTokenUserList()
    }

    func onAppear() {
        Analytics.log(.manageTokensScreenOpened)
        loader.reset(enteredSearchText.value)
    }

    func onDisappear() {
        DispatchQueue.main.async {
            self.enteredSearchText.value = ""
        }
    }

    func fetch() {
        loader.fetch(enteredSearchText.value)
    }

    /// Obtain supported token list from UserWalletModels to determine the cell action typeю
    /// Should be reset after updating the list of tokens
    func updateAlreadyExistTokenUserList() {
        let storageConverter = StorageEntryConverter()

        let customEntriesList = userWalletRepository.models
            .map { $0.userTokenListManager }
            .flatMap { userTokenListManager in
                userTokenListManager.userTokensList.entries
            }

        let tokenItemList = customEntriesList
            .filter {
                !$0.isCustom
            }
            .map {
                let blockchain = $0.blockchainNetwork.blockchain

                guard let token = storageConverter.convertToToken($0) else {
                    return TokenItem.blockchain(blockchain)
                }

                return TokenItem.token(token, blockchain)
            }

        cacheExistTokenUserList = tokenItemList
    }
}

// MARK: - Private

private extension ManageTokensViewModel {
    func bind() {
        enteredSearchText
            .dropFirst()
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] string in
                if !string.isEmpty {
                    Analytics.log(.tokenSearched)
                }

                self?.loader.fetch(string)
            }
            .store(in: &bag)

        derivationManagers = [:]
        userWalletRepository.models.forEach { derivationManagers[$0.userWalletId] = 0 }

        userWalletRepository.models.forEach { model in
            model.userTokensManager
                .derivationManager?
                .pendingDerivationsCount
                .sink(
                    receiveValue: { [weak self] countDerivation in
                        self?.derivationManagers[model.userWalletId] = countDerivation
                    }
                )
                .store(in: &bag)
        }
    }

    func setupListDataLoader() -> ListDataLoader {
        let supportedBlockchains = SupportedBlockchains.all
        let loader = ListDataLoader(supportedBlockchains: supportedBlockchains)

        loader.$items
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] items in
                guard let self = self else {
                    return
                }

                tokenViewModels = items.compactMap { self.mapToTokenViewModel(coinModel: $0) }
                updateQuote(by: items.map { $0.id })
            })
            .store(in: &bag)

        return loader
    }

    // MARK: - Private Implementation

    private func actionType(for coinModel: CoinModel) -> ManageTokensItemViewModel.Action {
        let isAlreadyExistToken = coinModel.items.contains(where: { tokenItem in
            cacheExistTokenUserList.contains(tokenItem)
        })

        return isAlreadyExistToken ? .edit : .add
    }

    private func mapToTokenViewModel(coinModel: CoinModel) -> ManageTokensItemViewModel {
        ManageTokensItemViewModel(
            coinModel: coinModel,
            action: actionType(for: coinModel),
            didTapAction: handle(action:with:)
        )
    }

    private func updateQuote(by coinIds: [String]) {
        tokenQuotesRepository.updateQuotes(coinIds: coinIds)
    }

    private func handle(action: ManageTokensItemViewModel.Action, with coinModel: CoinModel) {
        switch action {
        case .info:
            // [REDACTED_TODO_COMMENT]
            break
        case .add, .edit:
            coordinator.openTokenSelector(with: coinModel.items)
        }
    }
}
