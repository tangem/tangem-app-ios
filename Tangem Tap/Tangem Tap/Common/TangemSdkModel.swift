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
    @Published var isToken: Bool = false
    @Published var hasAccount: Bool = false
    @Published var dataLoaded: Bool = false
    @Published var name: String = ""
    @Published var usdBalance: String = ""
    @Published var balance: String = "34 BTC"
    @Published var noAccountMessage: String = ""
    @Published var secondaryBalance: String = "564 BTC"
    @Published var secondaryName: String = "Ethereum"
    @Published var address: String = ""
    @Published var payId: PayIdStatus = .notSupported
    
    internal init(card: Card) {
        self.card = card
        setupModel()
    }
    
    func setupModel() {
        hasWallet = true
        hasAccount = true
        dataLoaded = true
        name = "Bitcoin"
        usdBalance = "$3.25"
        isToken = false
        address = "0x132756128764bgnjk4hjvbkv3k,gj123h41k2j3g4123h4124nblk"
        payId = .notCreated
        //noAccountMessage = "Load 10+ XLM to create account"
    }
}
