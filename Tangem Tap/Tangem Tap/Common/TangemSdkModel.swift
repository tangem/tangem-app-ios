//
//  TangemSdkModel.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class TangemSdkModel: ObservableObject {
    @Published var wallet: WalletModel? = nil
    
    lazy var tangemSdk: TangemSdk = {
        let sdk = TangemSdk()
        return sdk
    }()
    
    func scan() {
        tangemSdk.scanCard { result in
            switch result {
            case .failure(let error):
                break
            case .success(let card):
                self.wallet = WalletModel(card: card)
            }
        }
    }
}


class WalletModel: ObservableObject {
    let card: Card
    
    @Published var hasWallet: Bool = false
    @Published var hasAccount: Bool = false
    @Published var dataLoaded: Bool = false
    @Published var blockchainName: String = ""
    @Published var usdBalance: String = ""
    @Published var balance: String = "—"
    
    internal init(card: Card) {
        self.card = card
        setupModel()
    }
    
    func setupModel() {
        hasWallet = true
        hasAccount = true
        dataLoaded = false
        blockchainName = "Bitcoin"
    }
}
