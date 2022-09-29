//
//  MultiWalletContentViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine

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
        totalBalanceManager: TotalBalanceProvider(userWalletModel: userWalletModel),
        isSingleCoinCard: false,
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
        userTokenListManager.loadAndSaveUserTokenList { [weak self] _ in
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
        output.openTokensList()
    }

    func tokenItemDidTap(_ itemViewModel: TokenItemViewModel) {
        output.openTokenDetails(itemViewModel)
    }
}

// MARK: - Private

private extension MultiWalletContentViewModel {
    func bind() {
        userWalletModel.subscribeToWalletModels()
            .map { wallets in
                wallets
                    .map { $0.$tokenItemViewModels }
                    .combineLatest()
            }
            .switchToLatest()
            .sink { [unowned self] wallets in
                updateView()
            }
            .store(in: &bag)

        userWalletModel.subscribeToWalletModels()
            .map { $0.isEmpty }
            .weakAssign(to: \.tokenListIsEmpty, on: self)
            .store(in: &bag)
    }

    func updateView() {
        let itemsViewModel = userWalletModel.getWalletModels().flatMap { $0.tokenItemViewModels }

        tokenListIsEmpty = itemsViewModel.isEmpty
        contentState = .loaded(itemsViewModel)
    }
}
