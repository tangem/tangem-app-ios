//
//  BitcoinCashWalletManager.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine
import TangemSdk
import RxSwift

class BitcoinCashNetworkManager {
    let provider: BlockchairProvider

    init(address: String) {
         self.provider = BlockchairProvider(address: address, endpoint: .bitcoinCash)
    }
    
    func getInfo() -> Single<BitcoinResponse> {
        return provider.getInfo()
    }
    
    @available(iOS 13.0, *)
    func getFee() -> AnyPublisher<BtcFee, Error> {
        return provider.getFee()
    }
    
    @available(iOS 13.0, *)
    func send(transaction: String) -> AnyPublisher<String, Error> {
        return provider.send(transaction: transaction)
    }
}
