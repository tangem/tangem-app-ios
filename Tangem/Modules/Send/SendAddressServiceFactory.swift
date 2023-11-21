//
//  SendAddressServiceFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct SendAddressServiceFactory {
    private let walletModel: WalletModel

    init(walletModel: WalletModel) {
        self.walletModel = walletModel
    }

    func build() -> SendAddressService {
        if let addressResolver = walletModel.addressResolver {
            return SendResolvedAddressService(walletModel: walletModel, addressResolver: addressResolver)
        } else {
            return DefaultSendAddressService(walletModel: walletModel)
        }
    }
}
