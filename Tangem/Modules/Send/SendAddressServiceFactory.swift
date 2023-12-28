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

    func makeService() -> SendAddressService {
        let addressService = AddressServiceFactory(blockchain: walletModel.wallet.blockchain).makeAddressService()
        let defaultSendAddressService = DefaultSendAddressService(walletAddresses: walletModel.wallet.addresses, addressService: addressService)

        if let addressResolver = walletModel.addressResolver {
            return SendResolvableAddressService(defaultSendAddressService: defaultSendAddressService, addressResolver: addressResolver)
        } else {
            return defaultSendAddressService
        }
    }
}
