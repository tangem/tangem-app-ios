//
//  MultiWalletContentViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdk

protocol MultiWalletContentViewModelOutput: AnyObject {
    func openCurrencySelection()
    func openTokenDetails(_ tokenItem: TokenItemViewModel)
    func openTokensList()
}

class MultiWalletContentViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var contentState: LoadingValue<[TokenItemViewModel]> = .loading
    @Published var tokenListIsEmpty: Bool = false

    lazy var totalSumBalanceViewModel = TotalSumBalanceViewModel(
        userWalletModel: userWalletModel,
        totalBalanceManager: TotalBalanceProvider(userWalletModel: userWalletModel, userWalletAmountType: nil),
        cardAmountType: nil,
        tapOnCurrencySymbol: output.openCurrencySelection
    )

    // MARK: Private

    private let cardModel: CardViewModel
    private let userWalletModel: UserWalletModel
    private let userTokenListManager: UserTokenListManager
    private unowned let output: MultiWalletContentViewModelOutput
    private var bag = Set<AnyCancellable>()

    private var isFirstTimeOnAppear: Bool = true

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

        bind()
    }

    func onRefresh(done: @escaping () -> Void) {
        userTokenListManager.updateLocalRepositoryFromServer { [weak self] _ in
            self?.userWalletModel.updateAndReloadWalletModels(completion: done)
        }
    }

    func onAppear() {
        if isFirstTimeOnAppear {
            onRefresh {}
            isFirstTimeOnAppear = false
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
        let viewModelsWithoutDerivation = userWalletModel.subscribeToEntriesWithoutDerivation()
            .map { [unowned self] entries in
                entries.flatMap(self.mapToTokenItemViewModels)
            }

        let walletModels = userWalletModel.subscribeToWalletModels()
            .map { wallets -> AnyPublisher<[TokenItemViewModel], Never> in
                if wallets.isEmpty {
                    return Just([]).eraseToAnyPublisher()
                }

                return wallets.map { $0.walletDidChange }
                    .combineLatest()
                    .map { _ in wallets.flatMap { $0.allTokenItemViewModels() } }
                    .eraseToAnyPublisher()
            }
            .switchToLatest()

        Publishers.CombineLatest(viewModelsWithoutDerivation, walletModels)
            .map(+)
            .sink { [unowned self] viewModels in
                updateView(viewModels: viewModels)
            }
            .store(in: &bag)

        userWalletModel.subscribeToWalletModels()
            .map { $0.isEmpty }
            .weakAssign(to: \.tokenListIsEmpty, on: self)
            .store(in: &bag)
    }

    func updateView(viewModels: [TokenItemViewModel]) {
        tokenListIsEmpty = viewModels.isEmpty
        contentState = .loaded(viewModels)
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
