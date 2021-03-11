//
//  AddNewTokenViewModel.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

class AddNewTokensViewModel: ViewModel {
    weak var assembly: Assembly!
    weak var navigation: NavigationCoordinator!
    weak var tokenItemsRepository: TokenItemsRepository!
    
    var availableBlockchains: [Blockchain]  { get { tokenItemsRepository.supportedItems.blockchains.map {$0}.sorted(by: { $0.displayName < $1.displayName }) } }
    var availableTokens: [Token]  { get { tokenItemsRepository.supportedItems.erc20Tokens.map {$0} } }
    
    @Published var searchText: String = ""
    @Published private(set) var pendingTokensUpdate: Set<Token> = []
    @Published var error: AlertBinder?
    
    private var bag: Set<AnyCancellable> = []
    
    let cardModel: CardViewModel
    
    init(cardModel: CardViewModel) {
        self.cardModel = cardModel
    }
    
    func addBlockchain(_ blockchain: Blockchain) {
        cardModel.addBlockchain(blockchain)
    }
    
    func removeBlockchain(_ blockchain: Blockchain) {
        cardModel.removeBlockchain(blockchain)
    }
    
    func isAdded(_ token: Token) -> Bool {
        tokenItemsRepository.items.contains(where: { $0.token == token })
    }
    
    func isAdded(_ blockchain: Blockchain) -> Bool {
        cardModel.wallets!.contains(where: { $0.blockchain == blockchain })
    }
    
    func addTokenToList(token: Token) {
        pendingTokensUpdate.insert(token)
        cardModel.erc20TokenWalletModel.addToken(token)?
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                if case let .failure(error) = completion {
                    print("Failed to add token to model", error)
                    self.error = error.alertBinder
                    self.pendingTokensUpdate.remove(token)
                }
            }, receiveValue: { _ in
                self.pendingTokensUpdate.remove(token)
            })
            .store(in: &bag)
    }
    
    func removeTokenFromList(token: Token) {
        cardModel.erc20TokenWalletModel.removeToken(token)
    }
    
    func clear() {
        searchText = ""
        pendingTokensUpdate = []
        bag = []
    }
    
}
