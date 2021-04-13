//
//  SignHandler.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import WalletConnectSwift

protocol WalletConnectHandler: class {
    var server: Server { get }
    func assertAddress(_ address: String) -> Bool
}

protocol SignHandler: WalletConnectHandler {
    func askToSign(request: Request, address: String, message: String, dataToSign: Data)
}

protocol WCSendTxHandler: WalletConnectHandler {
    func askToMakeTx(request: Request, ethTx: EthTransaction)
}
