//
//  MultiWalletContentViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdk

protocol MultiWalletContentViewModelOutput: OpenCurrencySelectionDelegate {
    func openTokenDetails(_ tokenItem: TokenItemViewModel)
    func openTokensList()
}

class MultiWalletContentViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var contentState: LoadingValue<[TokenItemViewModel]> = .loading
    @Published var tokenListIsEmpty: Bool = true

    lazy var totalSumBalanceViewModel = TotalSumBalanceViewModel(
        userWalletModel: userWalletModel,
        cardAmountType: nil,
        tapOnCurrencySymbol: output
    )

    // MARK: Private

    private unowned let output: MultiWalletContentViewModelOutput

    private let cardModel: CardViewModel
    private let userWalletModel: UserWalletModel
    private let userTokenListManager: UserTokenListManager
    private var bag = Set<AnyCancellable>()

    init(
        cardModel: CardViewModel,
        userWalletModel: UserWalletModel,
        userTokenListManager: UserTokenListManager,
        output: MultiWalletContentViewModelOutput
    ) {
        self.cardModel = cardModel
        self.userWalletModel = userWalletModel
        self.userTokenListManager = userTokenListManager
        self.output = output

        tokenListIsEmpty = userWalletModel.getSavedEntries().isEmpty
        bind()

        userWalletModel.updateWalletModels()
    }

    func onRefresh(silent: Bool = true, done: @escaping () -> Void) {
        if cardModel.hasTokenSynchronization {
            userTokenListManager.updateLocalRepositoryFromServer { [weak self] _ in
                self?.userWalletModel.updateAndReloadWalletModels(silent: silent, completion: done)
            }
        } else {
            userWalletModel.updateAndReloadWalletModels(silent: silent, completion: done)
        }
    }

    func openTokensList() {
        Analytics.log(.buttonManageTokens)
        output.openTokensList()
    }

    func tokenItemDidTap(_ itemViewModel: TokenItemViewModel) {
        output.openTokenDetails(itemViewModel)
    }
}

// MARK: - Private

private extension MultiWalletContentViewModel {
    func bind() {
        let entriesWithoutDerivation = userWalletModel
            .subscribeToEntriesWithoutDerivation()
            .dropFirst()
            .removeDuplicates()

        let newWalletModels = userWalletModel.subscribeToWalletModels()
            .dropFirst()
            .share()

        let walletModelsDidChange = newWalletModels
            .filter { !$0.isEmpty }
            .map { wallets -> AnyPublisher<Void, Never> in
                Publishers.MergeMany(wallets.map { $0.walletDidChange })
                    .mapVoid()
                    .eraseToAnyPublisher()
            }
            .switchToLatest()

        Publishers.Merge3(
            newWalletModels.mapVoid(),
            walletModelsDidChange.mapVoid(),
            entriesWithoutDerivation.mapVoid()
        )
        .receive(on: DispatchQueue.global())
        .map { [weak self] _ -> [TokenItemViewModel] in
            /// `unowned` will be crashed when the wallet which currently open is deleted from the list of saved wallet
            self?.collectTokenItemViewModels() ?? []
        }
        .removeDuplicates()
        .receive(on: RunLoop.main)
        .sink { [weak self] viewModels in
            self?.updateView(viewModels: viewModels)
        }
        .store(in: &bag)
    }

    func updateView(viewModels: [TokenItemViewModel]) {
        if tokenListIsEmpty != viewModels.isEmpty {
            tokenListIsEmpty = viewModels.isEmpty
        }

        contentState = .loaded(viewModels)
    }

    func collectTokenItemViewModels() -> [TokenItemViewModel] {
        let entries = userWalletModel.getSavedEntries()
        let walletModels = userWalletModel.getWalletModels()
        return entries.reduce([]) { result, entry in
            if let walletModel = walletModels.first(where: { $0.blockchainNetwork == entry.blockchainNetwork }) {
                return result + walletModel.allTokenItemViewModels()
            }

            return result + mapToTokenItemViewModels(entry: entry)
        }
    }

    func mapToTokenItemViewModels(entry: StorageEntry) -> [TokenItemViewModel] {
        let network = entry.blockchainNetwork
        var items: [TokenItemViewModel] = [
            TokenItemViewModel(
                state: .noDerivation,
                name: network.blockchain.displayName,
                blockchainNetwork: network,
                amountType: .coin,
                isCustom: false
            ),
        ]

        items += entry.tokens.map { token in
            TokenItemViewModel(
                state: .noDerivation,
                name: token.name,
                blockchainNetwork: network,
                amountType: .token(value: token),
                isCustom: token.isCustom
            )
        }

        return items
    }
}
