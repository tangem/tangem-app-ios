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

        bind()
    }

    func tokenItemDidTap(_ wallet: TokenItemViewModel) {
        walletDidTap(wallet)
    }

    func onAppear() {
        refreshTokens()
    }

    func refreshTokens(result: @escaping (Result<Void, Error>) -> Void = { _ in }) {
        // 1. Load and save tokens from API if it recieved succesefully
        // 2. Show list from API throught creates WalletModels in CardModel
        // 3. Update rates for each wallet model with skeleton
        // 4. Profit. Show actual information

        // 1. Load and save tokens from API if it recieved succesefully
        loadTokensSubscribtion = userTokenListManager.loadAndSaveUserTokenList()
            .tryMap { [unowned self] list -> AnyPublisher<Void, Error> in
                // Just update wallet models from repository
                self.walletListManager.updateWalletModels()

//                self.updateView()

                // Update walletModels with capturing the AnyPublisher response
                return self.walletListManager.reloadAllWalletModels()
            }
            .switchToLatest()
            .receiveCompletion { [unowned self] completion in
                switch completion {
                case .finished:
                    self.updateView()
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
//    var bag: Set<AnyCancellable> = []
}

// MARK: - Private

private extension WalletTokenListViewModel {
    func updateView() {
        let itemsViewModel = walletListManager.getWalletModels().flatMap { $0.tokenItemViewModels }

        contentState = itemsViewModel.isEmpty ? .empty : .loaded(itemsViewModel)
    }

    func bind() {
        subscribeWalletModelsBag = walletListManager.subscribeWalletModels()
            .print("WalletModels")
            .receiveValue { [unowned self] _ in
                self.updateView()
            }

//            .map {
//                $0.reduce([]) { $0 + $1.tokenItemViewModels }
//            }
//            .print("WalletModels")
//            .flatMap { [unowned self] walletModels -> AnyPublisher<[TokenItemViewModel], Never> in
//                let publishers = walletModels.forEach { walletModel in
//                    walletModel.$tokenItemViewModels.receiveValue { models in
//                        print("models", walletModel.state, models.count)
//                    }
//                    .store(in: &bag)
//                }

//                let publishers: [AnyPublisher<[TokenItemViewModel], Never>] = models.reduce([]) {
//                    $0 + $1.$tokenItemViewModels.eraseToAnyPublisher()
//                }
//                let publishers = walletModels.map { walletModel in
//                    walletModel.$tokenItemViewModels
//                        .collect(walletModel.tokenItemViewModels.count)
//                        .map { $0.reduce([], +) }
//                }
//
//                return Publishers.MergeMany(publishers)
//                    .collect(publishers.count) //
//                    .map { $0.reduce([], +) }
//                    .eraseToAnyPublisher()

//                return models.publisher
//                    .flatMap(\.tokenItemViewModels.publisher)
//                    .collect()
//                    .eraseToAnyPublisher()
//            }
//            .print("MergeMany")
//            .receiveValue { [unowned self] itemsViewModel in
//                print("itemsViewModel", itemsViewModel.map { $0.blockchainNetwork.blockchain.displayName })
//                if itemsViewModel.isEmpty {
//                    contentState = .empty
//                } else {
//                    contentState = .loaded(itemsViewModel)
//                }
//            }
    }
}
