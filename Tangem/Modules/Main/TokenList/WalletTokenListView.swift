//
//  TokenListView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

enum ContentState<Data> {
    case loading
    case loaded(_ content: Data)
    case error(error: Error)
}

protocol UserTokenListManager {
    func subscribeToCurrentTokenList() -> AnyPublisher<UserTokenList, Error>
    
    func loadUserTokenList()
    func saveUserTokens(tokens: [UserTokenList.Token])
}

struct CommonUserTokenListManager {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService
    
    private var currentTokenListSubject = PassthroughSubject<UserTokenList, Error>()
}

extension CommonUserTokenListManager: UserTokenListManager {
    func subscribeToCurrentTokenList() -> AnyPublisher<UserTokenList, Error> {
        currentTokenListSubject.eraseToAnyPublisher()
    }
    
    func saveUserTokens(tokens: [UserTokenList.Token]) {
        <#code#>
    }
    
    func loadUserTokenList() {
        
    }
}

class WalletTokenListViewModel: ObservableObject {
    // MARK: - ViewState

//    [REDACTED_USERNAME] var tokenViewModels: [TokenItemViewModel] = []
    @Published var contentState: ContentState<[TokenItemViewModel]> = .loading

    // MARK: - Private

    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService
    private let walletDidTap: (TokenItemViewModel) -> ()
    private let cardModel: CardViewModel
    private let accountId: String

    private var loadTokensSubscribtion: AnyCancellable?

    init(cardModel: CardViewModel, walletDidTap: @escaping (TokenItemViewModel) -> ()) {
        self.walletDidTap = walletDidTap
        self.cardModel = cardModel
//        self.tokenViewModels =
        self.accountId = cardModel.cardInfo.card.accountID
    }

    func tokenItemDidTap(_ wallet: TokenItemViewModel) {
        walletDidTap(wallet)
    }

//    func updateTokenViewModels(_ models: [TokenItemViewModel]) {
//        self.tokenViewModels = models
//    }

    func onAppear() {
        loadTokensSubscribtion = tangemApiService.loadTokens(key: accountId)
            .sink { completion in
                print(completion)
            } receiveValue: { [unowned self] list in
                self.contentState = .loaded(
                    cardModel.walletModels?.flatMap { $0.tokenItemViewModels } ?? []
                )
                print(list)
            }
    }
}

// MARK: - Private

private extension WalletTokenListViewModel {
    func bind() {
//        tangemApiService.loadCoins(requestModel: <#T##CoinsListRequestModel#>)
//        [REDACTED_TODO_COMMENT]
    }
}

struct WalletTokenListView: View {
    @ObservedObject private var viewModel: WalletTokenListViewModel

    init(viewModel: WalletTokenListViewModel) {
        self.viewModel = viewModel
    }

    // I hope will be redesign
    var body: some View {
        Group {
            switch viewModel.contentState {
            case .loading:
                ActivityIndicatorView()

            case let .loaded(viewModels):
                VStack(alignment: .leading, spacing: 6) {
                    Text("main_tokens".localized)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.tangemTextGray)
                        .padding([.leading, .top], 16)

                    ForEach(viewModels) { item in
                        VStack {
                            Button(action: { viewModel.tokenItemDidTap(item) }) {
                                TokenItemView(item: item)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 15)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(TangemTokenButtonStyle())

                            if viewModels.last != item {
                                Separator(height: 1, padding: 0, color: .tangemBgGray2)
                                    .padding(.leading, 68)
                            }
                        }
                    }
                }
                .background(Color.white)
                .cornerRadius(14)
                .padding(.horizontal, 16)

            case let .error(error):
                Text(error.localizedDescription)
            }
        }
        .onAppear(perform: viewModel.onAppear)
    }
}
