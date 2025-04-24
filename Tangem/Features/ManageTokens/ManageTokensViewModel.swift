//
//  ManageTokensViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import CombineExt
import TangemLocalization
import struct TangemUIUtils.AlertBinder

class ManageTokensViewModel: ObservableObject {
    var manageTokensListViewModel: ManageTokensListViewModel!

    @Published var customTokensList: [CustomTokenItemViewInfo] = []
    @Published var searchText = ""
    @Published var isPendingListEmpty = true
    @Published var isSavingChanges = false
    @Published var alert: AlertBinder?

    private let adapter: ManageTokensAdapter
    private let userTokensManager: UserTokensManager
    private let walletModelsManager: WalletModelsManager
    private weak var coordinator: ManageTokensRoutable?

    private let customTokensFullList = CurrentValueSubject<[CustomTokenItemViewInfo], Never>([])
    private var bag = Set<AnyCancellable>()

    init(
        adapter: ManageTokensAdapter,
        userTokensManager: UserTokensManager,
        walletModelsManager: WalletModelsManager,
        coordinator: ManageTokensRoutable?
    ) {
        self.adapter = adapter
        self.userTokensManager = userTokensManager
        self.walletModelsManager = walletModelsManager
        self.coordinator = coordinator

        manageTokensListViewModel = .init(
            loader: self,
            listItemsViewModelsPublisher: adapter.listItemsViewModelsPublisher
        )

        bind()
    }

    func saveChanges() {
        isSavingChanges = true

        adapter.saveChanges { [weak self] result in
            guard let self else { return }

            isSavingChanges = false
            switch result {
            case .success:
                adapter.resetAdapter()
                showPortfolioUpdatedToast()
            case .failure(let failure):
                if failure.isUserCancelled {
                    return
                }

                alert = failure.alertBinder
            }
        }
    }

    func removeCustomToken(_ info: CustomTokenItemViewInfo) {
        let tokenItem = info.tokenItem
        let alertBuilder = HideTokenAlertBuilder()
        if userTokensManager.canRemove(tokenItem) {
            alert = alertBuilder.hideTokenAlert(tokenItem: tokenItem, hideAction: { [weak self] in
                self?.userTokensManager.remove(tokenItem)
                self?.showPortfolioUpdatedToast()
            })
        } else {
            alert = alertBuilder.unableToHideTokenAlert(tokenItem: tokenItem)
        }
    }

    private func bind() {
        adapter
            .isPendingListsEmptyPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.isPendingListEmpty, on: self, ownership: .weak)
            .store(in: &bag)

        adapter
            .alertPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.alert, on: self, ownership: .weak)
            .store(in: &bag)

        $searchText
            .dropFirst()
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { viewModel, searchText in
                viewModel.adapter.fetch(searchText)
            }
            .store(in: &bag)

        $searchText
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .combineLatest(customTokensFullList)
            .map { searchText, tokensList in
                if searchText.isEmpty {
                    return tokensList
                }

                return tokensList.filter {
                    $0.name.range(of: searchText, options: .caseInsensitive) != nil ||
                        $0.symbol.range(of: searchText, options: .caseInsensitive) != nil
                }
            }
            .assign(to: \.customTokensList, on: self, ownership: .weak)
            .store(in: &bag)

        walletModelsManager.walletModelsPublisher
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .map { viewModel, walletModels in
                viewModel.prepareCustomTokensList(from: walletModels)
            }
            .assign(to: \.value, on: customTokensFullList, ownership: .weak)
            .store(in: &bag)
    }

    private func prepareCustomTokensList(from walletModels: [any WalletModel]) -> [CustomTokenItemViewInfo] {
        let iconInfoBuilder = TokenIconInfoBuilder()
        return walletModels.compactMap {
            guard $0.isCustom else {
                return nil
            }

            return .init(
                tokenItem: $0.tokenItem,
                iconInfo: iconInfoBuilder.build(from: $0.tokenItem, isCustom: true),
                name: $0.name,
                symbol: $0.tokenItem.currencySymbol
            )
        }
    }

    private func showPortfolioUpdatedToast() {
        Toast(view: SuccessToast(text: Localization.manageTokensToastPortfolioUpdated))
            .present(
                layout: .top(padding: 20),
                type: .temporary()
            )
    }
}

extension ManageTokensViewModel: ManageTokensListLoader {
    var hasNextPage: Bool {
        adapter.hasNextPage
    }

    func fetch() {
        adapter.fetch(searchText)
    }
}

// MARK: - Navigation

extension ManageTokensViewModel {
    func openAddCustomToken() {
        coordinator?.openAddCustomToken()
    }
}
