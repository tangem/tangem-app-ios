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
    @Published var loadingError: Error?

    // MARK: - Private

    private let userTokenListManager: UserTokenListManager
    private let walletListManager: WalletListManager
    private let walletDidTap: (TokenItemViewModel) -> ()

    private var loadTokensSubscribtion: AnyCancellable?
    private var subscribeWalletModelsBag: AnyCancellable?

    init(
        userTokenListManager: UserTokenListManager,
        walletListManager: WalletListManager,
        walletDidTap: @escaping (TokenItemViewModel) -> ()
    ) {
        self.userTokenListManager = userTokenListManager
        self.walletListManager = walletListManager
        self.walletDidTap = walletDidTap
    }

    func tokenItemDidTap(_ wallet: TokenItemViewModel) {
        walletDidTap(wallet)
    }

    func onAppear() {
        refreshTokens { _ in }
    }

    func refreshTokens(result: @escaping (Result<Void, Error>) -> Void) {
        // 1. Load and save tokens from API if it recieved succesefully
        // 2. Show list from API throught creates WalletModels in CardModel
        // 3. Update rates for each wallet model with skeleton
        // 4. Profit. Show actual information

        // 1. Load and save tokens from API if it recieved succesefully
        loadTokensSubscribtion = userTokenListManager.loadAndSaveUserTokenList()
            .tryMap { [unowned self] list -> AnyPublisher<Void, Error> in
                // Just update wallet models from repository
                self.walletListManager.updateWalletModels()

                // Update walletModels with capturing the AnyPublisher response
                return self.walletListManager.reloadAllWalletModels()
            }
            .switchToLatest()
            .receiveCompletion { [unowned self] completion in
                switch completion {
                case .finished:
                    // Call callback result to close "Pull-to-refresh" animating
                    result(.success(()))

                case let .failure(error):
                    loadingError = error
                    contentState = .error(error: error)
                    // Call callback result to close "Pull-to-refresh" animating
                    result(.failure(error))
                }
            }
    }
}

// MARK: - Private

private extension WalletTokenListViewModel {
    func bind() {
        subscribeWalletModelsBag = walletListManager.subscribeWalletModels()
            .map { $0.flatMap({ $0.tokenItemViewModels }) }
            .receiveValue { [unowned self] itemsViewModel in
                if !itemsViewModel.isEmpty {
                    contentState = .empty
                } else {
                    contentState = .loaded(itemsViewModel)
                }
            }
    }
}
