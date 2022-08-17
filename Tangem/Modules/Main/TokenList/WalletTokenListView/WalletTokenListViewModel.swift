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

    private let walletDidTap: (TokenItemViewModel) -> ()
    private let cardModel: CardViewModel

    private let userTokenListManager: UserTokenListManager

    private var loadTokensSubscribtion: AnyCancellable?

    private var cardInfo: CardInfo { cardModel.cardInfo }
//    private var accountId: String { cardInfo.card.accountID }

    init(cardModel: CardViewModel, walletDidTap: @escaping (TokenItemViewModel) -> ()) {
        self.walletDidTap = walletDidTap
        self.cardModel = cardModel
//        self.cardInfo = cardModel.cardInfo
//        self.accountId = cardModel.cardInfo.card.accountID

        userTokenListManager = CommonUserTokenListManager(
            accountId: cardModel.cardInfo.card.accountID,
            cardId: cardModel.cardInfo.card.cardId
        )
    }

    func tokenItemDidTap(_ wallet: TokenItemViewModel) {
        walletDidTap(wallet)
    }

    func onAppear() {
        updateView()
//        loadTokensSubscribtion = refreshTokens().sink()
    }

    func refreshTokens() -> AnyPublisher<Void, Error>  {
        userTokenListManager.loadUserTokenList()
//            .tryMap { [weak self] list -> AnyPublisher<Void, Error> in
//                guard let self = self else {
//                    throw CommonError.masterReleased
//                }
//
//                self.cardModel.updateState()
//
//                return self.cardModel.refresh()
//                    .eraseToAnyPublisher()
//                    .mapVoid()
//                    .setFailureType(to: Error.self)
//                    .eraseToAnyPublisher()
//            }
//            .switchToLatest()
            .handleEvents(receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished:
                    self?.updateView()
                case let .failure(error):
                    self?.contentState = .error(error: error)
                }
            })
            .mapVoid()
            .eraseToAnyPublisher()
//
//            .sink { [unowned self] completion in
//                guard case let .failure(error) = completion else {
//                    return
//                }
//
//                contentState = .error(error: error)
//            } receiveValue: { [unowned self] list in
//                print("♻️ Wallet model loading state changed")
//                withAnimation {
//                    done()
//                }
//
//                self.updateView(by: list)
//            }
    }


}

// MARK: - Private

private extension WalletTokenListViewModel {
    func updateView() {
//        self.cardModel.updateState()

        if let models = cardModel.walletModels?.flatMap({ $0.tokenItemViewModels }), !models.isEmpty {
            contentState = .loaded(models)
        } else {
            contentState = .empty
        }

//        loadTokensSubscribtion = cardModel.update().sink()
    }
}
