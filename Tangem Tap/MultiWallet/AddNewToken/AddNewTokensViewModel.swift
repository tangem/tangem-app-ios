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
    
    let cardModel: CardViewModel
    
    init(cardModel: CardViewModel) {
        self.cardModel = cardModel
    }
    
    func addBlockchain(_ blockchain: Blockchain) {
        cardModel.addBlockchain(blockchain)
    }
    
    func isAdded(_ token: Token) -> Bool {
        tokenItemsRepository.items.contains(where: { $0.token == token })
    }
    
    func isAdded(_ blockchain: Blockchain) -> Bool {
        cardModel.wallets!.contains(where: { $0.blockchain == blockchain })
    }
    
    func addTokenToList(token: Token) {
        pendingTokensUpdate.insert(token)
        cardModel.addToken(token) {[weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let token):
                self.pendingTokensUpdate.remove(token)
            case .failure(let error):
                self.error = error.alertBinder
                self.pendingTokensUpdate.remove(token)
            }
        }
    }
    
    func clear() {
        searchText = ""
        pendingTokensUpdate = []
    }
    
}
