//
//  WalletTokenListViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine

class WalletTokenListViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var contentState: ContentState<[TokenItemViewModel]> = .loading

    // MARK: - Private

    private let userTokenListManager: UserTokenListManager
    private let userWalletModel: UserWalletModel
    private let didTapWallet: (TokenItemViewModel) -> ()

    private var isFirstTimeOnAppear: Bool = true
    private var loadTokensSubscribtion: AnyCancellable?
    private var subscribeWalletModelsBag: AnyCancellable?
    private var subscribeToTokenItemViewModelsChangesBag: AnyCancellable?

    init(
        userTokenListManager: UserTokenListManager,
        userWalletModel: UserWalletModel,
        didTapWallet: @escaping (TokenItemViewModel) -> ()
    ) {
        self.userTokenListManager = userTokenListManager
        self.userWalletModel = userWalletModel
        self.didTapWallet = didTapWallet

        bind()
    }

    func tokenItemDidTap(_ wallet: TokenItemViewModel) {
        didTapWallet(wallet)
    }

    func onAppear() {
        if isFirstTimeOnAppear {
            refreshTokens()
            isFirstTimeOnAppear = false
        }
    }

    func refreshTokens(result: @escaping (Result<Void, Error>) -> Void = { _ in }) {
        // 1. Load and save tokens from API if it recieved succesefully
        // 2. Show walletModel list from local repository
        // 3. Update rates for each wallet model with skeleton
        // 4. Profit. Show actual information
        userTokenListManager.loadAndSaveUserTokenList { [weak self] _ in
            self?.userWalletModel.updateAndReloadWalletModels(showProgressLoading: true, result: result)
        }
    }
}

// MARK: - Private

private extension WalletTokenListViewModel {
    func updateView() {
        let itemsViewModel = userWalletModel.getWalletModels().flatMap { $0.tokenItemViewModels }

        contentState = itemsViewModel.isEmpty ? .empty : .loaded(itemsViewModel)
    }

    func bind() {
        subscribeWalletModelsBag = userWalletModel.subscribeToWalletModels()
            .receiveValue { [unowned self] wallets in
                self.subscribeToTokenItemViewModelsChanges(wallets: wallets)
                self.updateView()
            }
    }

    func subscribeToTokenItemViewModelsChanges(wallets: [WalletModel]) {
        let publishers = wallets.map { $0.objectWillChange }
        subscribeToTokenItemViewModelsChangesBag = Publishers.MergeMany(publishers)
            .collect(publishers.count)
            .receiveValue { [unowned self] _ in
                self.updateView()
            }
    }
}
