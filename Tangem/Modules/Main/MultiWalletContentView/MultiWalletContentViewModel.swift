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
    @Published var tokenListIsEmpty: Bool = true

    lazy var totalSumBalanceViewModel = TotalSumBalanceViewModel(
        userWalletModel: userWalletModel,
        totalBalanceManager: totalBalanceManager,
        cardAmountType: nil,
        tapOnCurrencySymbol: output.openCurrencySelection
    )

    // MARK: Private

    private let cardModel: CardViewModel
    private let userWalletModel: UserWalletModel
    private let userTokenListManager: UserTokenListManager
    private unowned let output: MultiWalletContentViewModelOutput
    private var bag = Set<AnyCancellable>()
    private lazy var totalBalanceManager = TotalBalanceProvider(
        userWalletModel: userWalletModel,
        userWalletAmountType: nil,
        totalBalanceAnalyticsService: TotalBalanceAnalyticsService(totalBalanceCardSupportInfo: totalBalanceCardSupportInfo)
    )
    private lazy var totalBalanceCardSupportInfo = TotalBalanceCardSupportInfo(
        cardBatchId: cardModel.batchId,
        cardNumber: cardModel.cardId
    )

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

    func onRefresh(silent: Bool = true, done: @escaping () -> Void) {
        userTokenListManager.updateLocalRepositoryFromServer { [weak self] _ in
            self?.userWalletModel.updateAndReloadWalletModels(silent: silent, completion: done)
        }
    }

    func onAppear() {
        if isFirstTimeOnAppear {
            onRefresh(silent: false) {}
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
        let entriesWithoutDerivation = userWalletModel
            .subscribeToEntriesWithoutDerivation()
            .removeDuplicates()

        let walletModels = userWalletModel.subscribeToWalletModels()
            .receive(on: DispatchQueue.global())
            .map { wallets -> AnyPublisher<Void, Never> in
                if wallets.isEmpty {
                    return .just
                }

                return wallets.map { $0.walletDidChange }
                    .combineLatest()
                    .map { _ in wallets.map { $0.state.isLoading } }
                    .removeDuplicates() // Update only if isLoading state changed
                    .mapVoid()
                    .eraseToAnyPublisher()
            }
            .switchToLatest()

        Publishers.CombineLatest(entriesWithoutDerivation, walletModels)
            .receive(on: DispatchQueue.global())
            .map { [unowned self] _ -> [TokenItemViewModel] in
                collectTokenItemViewModels()
            }
            .receive(on: RunLoop.main)
            .sink { [unowned self] viewModels in
                updateView(viewModels: viewModels)
            }
            .store(in: &bag)
    }

    func updateView(viewModels: [TokenItemViewModel]) {
        tokenListIsEmpty = viewModels.isEmpty
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
