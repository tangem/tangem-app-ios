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

    private let walletDidTap: (TokenItemViewModel) -> ()
    private let cardModel: CardViewModel
    private let userTokenListManager: UserTokenListManager

    private var loadTokensSubscribtion: AnyCancellable?

    init(cardModel: CardViewModel, walletDidTap: @escaping (TokenItemViewModel) -> ()) {
        self.walletDidTap = walletDidTap
        self.cardModel = cardModel

        userTokenListManager = CommonUserTokenListManager(
            accountId: cardModel.accountID,
            cardId: cardModel.cardId
        )
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
            .tryMap { [weak self] list -> AnyPublisher<Void, Error> in
                guard let self = self else {
                    throw CommonError.masterReleased
                }

                // Just update state with recreate walletModels without any another updates
                self.cardModel.updateState(shouldUpdate: false)
                // Show exist wallet models with the skeletons
                self.updateView()

                // Update walletModels with capturing the AnyPublisher response
                return self.cardModel.update(showProgressLoading: false)
            }
            .switchToLatest()
            .receiveCompletion { [unowned self] completion in
                switch completion {
                case .finished:
                    // Show exist wallet models with the actual information
                    updateView()

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
    func updateView() {
        if let models = cardModel.walletModels?.flatMap({ $0.tokenItemViewModels }), !models.isEmpty {
            contentState = .loaded(models)
        } else {
            contentState = .empty
        }
    }
}
