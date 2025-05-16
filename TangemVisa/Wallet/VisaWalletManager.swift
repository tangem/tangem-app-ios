//
//  VisaWalletManager.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

public class VisaWalletManager {
    let wallet: Wallet
    
    private let isTestnet: Bool
    private let utilities: VisaUtilities
    private let walletPublicKey: Wallet.PublicKey
    private var paymentAccountInteractor: VisaPaymentAccountInteractor?
    
    init(
        isTestnet: Bool,
        walletPublicKey: Wallet.PublicKey
    ) {
        self.isTestnet = isTestnet
        self.walletPublicKey = walletPublicKey
        let utilities = VisaUtilities(isTestnet: isTestnet)
        self.utilities = utilities
        
        wallet = .init(blockchain: utilities.visaBlockchain, addresses: [:])
        setupTask()
    }

    func update() async throws {
        
    }
    
    private func setupTask() {
        
    }
}
