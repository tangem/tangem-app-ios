//
//  TangemSdkModel.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk
import Combine

class TangemSdkModel: ObservableObject {
    @Published var walletViewModel: WalletViewModel! = nil
    @Published var cardViewModel: CardViewModel! = nil
    
    @Published var openDetails = false
    var walletManager: WalletManager? = nil
    var bag: AnyCancellable? = nil
    
    lazy var tangemSdk: TangemSdk = {
        let sdk = TangemSdk()
        return sdk
    }()
    
    func scan() {
        // setupCard(Card.testCard)
        tangemSdk.scanCard { result in
            switch result {
            case .failure:
                //[REDACTED_TODO_COMMENT]
                break
            case .success(let card):
                self.setupCard(card)
                self.openDetails = true
            }
        }
    }
    
    func setupCard(_ card: Card) {
        guard let status = card.status else {
            return
        }
        
        self.cardViewModel = CardViewModel(card: card)
        if status == .loaded, let walletManager = WalletManagerFactory().makeWalletManager(from: card) {
            self.walletManager = walletManager
            walletViewModel = WalletViewModel(wallet: walletManager.wallet)
            bag = walletManager.$wallet
                .sink(receiveValue: {[weak self] wallet in
                    self?.walletViewModel = WalletViewModel(wallet: wallet)
                })
            self.updateWallet()
        } else {
            reset()
        }
    }
    
    public func updateWallet() {
        walletViewModel!.state = .loading
        walletManager?.update { result in
            switch result {
            case .success:
                self.walletViewModel!.state = .loaded
            case .failure(let error):
                self.walletViewModel!.state = .loadingFailed(message: error.detailedError.localizedDescription)
            }
        }
    }
    
    private func reset() {
        bag?.cancel()
        walletManager = nil
        walletViewModel = nil
    }
}

struct CardViewModel {
    let card: Card
}

enum WalletState {
    case initialized
    case loading
    case loaded
    case accountNotCreated(message: String)
    case loadingFailed(message: String)
}

struct WalletViewModel {
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
    
    var state: WalletState = .initialized
    let address: String
    var payId: PayIdStatus
    
    init(wallet: Wallet) {
        self.wallet = wallet
        address = wallet.address
        payId = .notCreated
        //noAccountMessage = "Load 10+ XLM to create account"
    }
}
