//
//  SendAddressServiceFactory.swift
//  Tangem
//
//  Created by Andrey Chukavin on 21.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct SendAddressServiceFactory {
    private let walletModel: WalletModel

    init(walletModel: WalletModel) {
        self.walletModel = walletModel
    }

    func make() -> SendAddressService {
        if let addressResolver = walletModel.addressResolver {
            return SendResolvableAddressService(walletModel: walletModel, addressResolver: addressResolver)
        } else {
            return DefaultSendAddressService(walletModel: walletModel)
        }
    }
}
