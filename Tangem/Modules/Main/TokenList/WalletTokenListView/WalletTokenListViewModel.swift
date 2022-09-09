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
    private let walletListManager: WalletListManager
    private let didTapWallet: (TokenItemViewModel) -> ()

    private var loadTokensSubscribtion: AnyCancellable?
    private var subscribeWalletModelsBag: AnyCancellable?
    private var subscribeToTokenItemViewModelsChangesBag: AnyCancellable?

    init(
        userTokenListManager: UserTokenListManager,
        walletListManager: WalletListManager,
        didTapWallet: @escaping (TokenItemViewModel) -> ()
    ) {
        self.userTokenListManager = userTokenListManager
        self.walletListManager = walletListManager
        self.didTapWallet = didTapWallet

        bind()
    }

    func tokenItemDidTap(_ wallet: TokenItemViewModel) {
        didTapWallet(wallet)
    }

    func onAppear() {
        refreshTokens()
    }

    func refreshTokens(result: @escaping (Result<Void, Error>) -> Void = { _ in }) {
        // 1. Load and save tokens from API if it recieved succesefully
        // 2. Show walletModel list from local repository
        // 3. Update rates for each wallet model with skeleton
        // 4. Profit. Show actual information
        loadTokensSubscribtion = userTokenListManager.loadAndSaveUserTokenList()
            .replaceError(with: UserTokenList(tokens: []))
            .tryMap { [unowned self] list -> AnyPublisher<Void, Error> in
                // Just update wallet models from repository
                self.walletListManager.updateWalletModels()

                // Update walletModels with capturing the AnyPublisher response
                return self.walletListManager.reloadWalletModels()
            }
            .switchToLatest()
            .receiveCompletion { [unowned self] completion in
                switch completion {
                case .finished:
                    // Call callback result to close "Pull-to-refresh" animating
                    result(.success(()))

                case let .failure(error):
                    // Call callback result to close "Pull-to-refresh" animating
                    result(.failure(error))
                }

                updateView()
            }
    }
}

// MARK: - Private

private extension WalletTokenListViewModel {
    func updateView() {
        let itemsViewModel = walletListManager.getWalletModels().flatMap { $0.tokenItemViewModels }

        contentState = itemsViewModel.isEmpty ? .empty : .loaded(itemsViewModel)
    }

    func bind() {
        subscribeWalletModelsBag = walletListManager.subscribeToWalletModels()
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
