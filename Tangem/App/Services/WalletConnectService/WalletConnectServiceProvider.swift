//
//  WalletConnectServiceProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct WalletConnectServiceProvider: WalletConnectServiceProviding {
    private(set) var service: WalletConnectService = .init(cardScanner: WalletConnectCardScanner())

    func initialize() {
        service.restore()
    }
}
