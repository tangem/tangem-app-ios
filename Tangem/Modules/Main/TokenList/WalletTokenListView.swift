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
    case empty
    case loaded(_ content: Data)
    case error(error: Error)

    var isEmpty: Bool {
        if case .empty = self {
            return true
        }

        return false
    }
}

protocol UserTokenListManager {
//    func subscribeToCurrentTokenList()

    func loadUserTokenList() -> AnyPublisher<UserTokenList, Error>
//    func saveUserTokens(tokens: [UserTokenList.Token])
}



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

    func refreshTokens() {
        loadTokensSubscribtion = userTokenListManager.loadUserTokenList()
            .sink { [unowned self] completion in
                guard case let .failure(error) = completion else {
                    return
                }

                contentState = .error(error: error)
            } receiveValue: { [unowned self] list in
                self.updateView(by: list)
            }
    }
}

// MARK: - Private

private extension WalletTokenListViewModel {
    func updateView(by list: UserTokenList) {
        cardModel.updateState()

        if let models = cardModel.walletModels?.flatMap({ $0.tokenItemViewModels }), !models.isEmpty {
            contentState = .loaded(models)
        } else {
            contentState = .empty
        }
    }
}

struct WalletTokenListView: View {
    @ObservedObject private var viewModel: WalletTokenListViewModel

    init(viewModel: WalletTokenListViewModel) {
        self.viewModel = viewModel
    }

    // I hope will be redesign
    var body: some View {
        if !viewModel.contentState.isEmpty {
            VStack(alignment: .center, spacing: 0) {
                Text("main_tokens".localized)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding([.leading, .top], 16)

                content
            }
            .frame(maxWidth: .infinity)
            .background(Colors.Background.plain)
            .cornerRadius(14)
            .padding(.horizontal, 16)
            .onAppear(perform: viewModel.refreshTokens)
        }
    }

    @ViewBuilder var content: some View {
        switch viewModel.contentState {
        case .loading:
            ActivityIndicatorView(color: .gray)
                .padding()

        case .empty:
            // Oops, user haven't added any tokens
           break

        case let .loaded(viewModels):
            VStack(alignment: .leading, spacing: 6) {
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


        case let .error(error):
            Text(error.localizedDescription)
                .padding()
        }
    }
}


struct WalletTokenListViewModel_Preview: PreviewProvider {
    static var previews: some View {
        ZStack {
            Colors.Background.secondary.edgesIgnoringSafeArea(.all)

            WalletTokenListView(viewModel: WalletTokenListViewModel(cardModel: .init(cardInfo: .init(card: .card, isTangemNote: false, isTangemWallet: false)), walletDidTap: { _ in

            }))
        }
        .previewLayout(.sizeThatFits)
    }
}
