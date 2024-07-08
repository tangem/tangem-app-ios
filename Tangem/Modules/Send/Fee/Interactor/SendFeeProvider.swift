//
//  SendFeeProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

protocol SendFeeProvider {
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error>
}

class CommonSendFeeProvider: SendFeeProvider {
    private let walletModel: WalletModel

    init(walletModel: WalletModel) {
        self.walletModel = walletModel
    }

    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], any Error> {
        walletModel.getFee(amount: amount, destination: destination)
    }
}
