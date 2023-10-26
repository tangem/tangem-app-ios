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

    @Injected(\.quotesRepository) private var tokenQuotesRepository: TokenQuotesRepository
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    // I can't use @Published here, because of swiftui redraw perfomance drop
    var enteredSearchText = CurrentValueSubject<String, Never>("")

    @Published var tokenViewModels: [ManageTokensItemViewModel] = []
    @Published var isLoading: Bool = true
    @Published var generateAddressesViewModel: GenerateAddressesViewModel?

    // MARK: - Properties

    var hasNextPage: Bool {
        loader.canFetchMore
    }

    private unowned let coordinator: ManageTokensRoutable

    private lazy var loader = setupListDataLoader()
    private let generateAddressProvider = ManageTokensGenerateAddressProvider()

    private var bag = Set<AnyCancellable>()
    private var cacheExistListCoinId: [String] = []
    private var pendingDerivationCountByWalletId: [UserWalletId: Int] = [:]

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
}

// MARK: - Private Implementation

private extension ManageTokensViewModel {
    /// Obtain supported token list from UserWalletModels to determine the cell action type
    /// Should be reset after updating the list of tokens
    func updateAlreadyExistTokenUserList() {
        let existEntriesList = userWalletRepository.models
            .map { $0.userTokenListManager }
            .flatMap { userTokenListManager in
                let entries = userTokenListManager.userTokensList.entries
                return entries.compactMap { $0.isCustom ? nil : $0.id }
            }

        cacheExistListCoinId = existEntriesList
    }

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

        // Used for update state generateAddressesViewModel property
        let pendingDerivationsCountPublishers = userWalletRepository.models
            .compactMap { model -> AnyPublisher<(UserWalletId, Int), Never>? in
                if let derivationManager = model.userTokensManager.derivationManager {
                    return derivationManager.pendingDerivationsCount
                        .map { (model.userWalletId, $0) }
                        .eraseToAnyPublisher()
                }

                return nil
            }

        Publishers.MergeMany(pendingDerivationsCountPublishers)
            .receiveValue { [weak self] id, count in
                self?.pendingDerivationCountByWalletId[id] = count
                self?.updateGenerateAddressesViewModel()
            }
            .store(in: &bag)

        // Used for update state actionType tokenViewModels list property
        let userTokensPublishers = userWalletRepository.models
            .map { $0.userTokenListManager.userTokensPublisher }

        Publishers.MergeMany(userTokensPublishers)
            .receiveValue { [weak self] value in
                guard let self = self else { return }

                updateAlreadyExistTokenUserList()

                tokenViewModels.forEach {
                    $0.action = self.actionType(for: $0.id)
                }
            }
            .store(in: &bag)
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

    private func actionType(for coinId: String) -> ManageTokensItemViewModel.Action {
        let isAlreadyExistToken = cacheExistListCoinId.contains(coinId)
        return isAlreadyExistToken ? .edit : .add
    }

    private func mapToTokenViewModel(coinModel: CoinModel) -> ManageTokensItemViewModel {
        ManageTokensItemViewModel(
            coinModel: coinModel,
            action: actionType(for: coinModel.id),
            didTapAction: handle(action:with:)
        )
    }

    private func updateQuote(by coinIds: [String]) {
        runTask(in: self) { root in
            await root.tokenQuotesRepository.loadQuotes(currencyIds: coinIds)
        }
    }

    private func handle(action: ManageTokensItemViewModel.Action, with coinModel: CoinModel) {
        switch action {
        case .info:
            // [REDACTED_TODO_COMMENT]
            break
        case .add, .edit:
            coordinator.openTokenSelector(coinId: coinModel.id, with: coinModel.items)
        }
    }

    private func updateGenerateAddressesViewModel() {
        guard pendingDerivationCountByWalletId.contains(where: { $0.value > 0 }) else {
            return generateAddressesViewModel = nil
        }

        generateAddressesViewModel = GenerateAddressesViewModel(
            numberOfNetworks: pendingDerivationCountByWalletId.map { $0.value }.reduce(0, +),
            currentWalletNumber: pendingDerivationCountByWalletId.filter { $0.value > 0 }.count,
            totalWalletNumber: userWalletRepository.userWallets.count,
            didTapGenerate: { [weak self] in
                guard let self = self else { return }

                guard let userWalletId = pendingDerivationCountByWalletId.first(where: { $0.value > 0 })?.key else {
                    return
                }

                generateAddressProvider.performDeriveIfNeeded(with: userWalletId)
            }
        )
    }
}
