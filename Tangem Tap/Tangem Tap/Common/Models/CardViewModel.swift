//
//  CardViewModel.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk
import Combine

class CardViewModel: Identifiable, ObservableObject {
    let card: Card
    let service = NetworkService()
    
    @Published var isWalletLoading: Bool = false
    @Published var loadingError: Error?
    @Published var payId: PayIdStatus = .notSupported
    @Published var balanceViewModel: BalanceViewModel!
    
    @Published var wallet: Wallet? = nil
    @Published var image: UIImage? = nil
    
    private var walletManager: WalletManager?
    private let verifyCardResponse: VerifyCardResponse?
    private var bag: AnyCancellable? = nil
    
    init(card: Card, verifyCardResponse: VerifyCardResponse? = nil) {
        self.card = card
        self.verifyCardResponse = verifyCardResponse
        if let walletManager = WalletManagerFactory().makeWalletManager(from: card) {
            self.walletManager = walletManager
            self.wallet = walletManager.wallet
            self.balanceViewModel = self.makeBalanceViewModel(from: walletManager.wallet)
            bag = walletManager.$wallet
                .sink(receiveValue: {[unowned self] wallet in
                    self.wallet = wallet
                    self.balanceViewModel = self.makeBalanceViewModel(from: wallet)
                    self.isWalletLoading = false
                })
            self.updateWallet()
            self.loadImage()
        }
    }
    
    public func updateWallet() {
        loadingError = nil
        isWalletLoading = true
        walletManager?.update { [weak self] result in
            if case let .failure(error) = result {
                self?.loadingError = error.detailedError
                self?.isWalletLoading = false
            }
        }
    }
    
    func loadImage() {
        guard image == nil else {
            return
        }
        
        guard let artworkId = verifyCardResponse?.artworkInfo?.id,
            let cid = card.cardId,
            let cardPublicKey = card.cardPublicKey else {
                self.image = UIImage(named: "card-default")
                return
        }
        
        service.request(TangemEndpoint.artwork(cid: cid, cardPublicKey: cardPublicKey, artworkId: artworkId)) {[weak self] result in
            switch result {
            case .success(let data):
                if let img = UIImage(data: data) {
                    self?.image = img
                }
            case .failure(let error):
                //[REDACTED_TODO_COMMENT]
                break
            }
        }
    }
    
    private func makeBalanceViewModel(from wallet: Wallet) -> BalanceViewModel? {
        let name = wallet.token != nil ? wallet.token!.displayName :  wallet.blockchain.displayName
        let secondaryName = wallet.token != nil ?  wallet.blockchain.displayName : ""
        
        let model = BalanceViewModel(isToken: wallet.token != nil,
                                dataLoaded: !wallet.amounts.isEmpty,
                                loadingError: self.loadingError?.localizedDescription,
                                name: name,
                                usdBalance: "-",
                                balance: wallet.amounts[.coin]?.description ?? "-",
                                secondaryBalance: "",
                                secondaryName: secondaryName)
        return model
    }
}

enum WalletState {
    case empty
    case initialized
    case loading
    case loaded
    case accountNotCreated(message: String)
    case loadingFailed(message: String)
}

/*class WalletViewModel {
    var balanceViewModel: BalanceViewModel {
        let name = wallet.token != nil ? wallet.token!.displayName :  wallet.blockchain.displayName
        let secondaryName = wallet.token != nil ?  wallet.blockchain.displayName : ""
        
        switch state {
        case .loadingFailed(let message):
            return BalanceViewModel(isToken: wallet.token != nil,
                                    dataLoaded: false,
                                    loadingError: message,
                                    name: name,
                                    usdBalance: "",
                                    balance: "-",
                                    secondaryBalance: "-",
                                    secondaryName: secondaryName)
        default:
            return BalanceViewModel(isToken: wallet.token != nil,
                                    dataLoaded: true,
                                    loadingError: nil,
                                    name: name,
                                    usdBalance: "-",
                                    balance: wallet.amounts[.coin]?.description ?? "-",
                                    secondaryBalance: "",
                                    secondaryName: secondaryName)
            
        }
    }
    
    let wallet: Wallet
    
    @Published var state: WalletState = .initialized
    let address: String
    var payId: PayIdStatus
    
    init(wallet: Wallet) {
        self.wallet = wallet
        address = wallet.address
        payId = .notCreated
        //noAccountMessage = "Load 10+ XLM to create account"
    }
    
    
}*/

struct BalanceViewModel {
    let isToken: Bool
    let dataLoaded: Bool
    let loadingError: String?
    let name: String
    let usdBalance: String
    let balance: String
    let secondaryBalance: String
    let secondaryName: String
}
