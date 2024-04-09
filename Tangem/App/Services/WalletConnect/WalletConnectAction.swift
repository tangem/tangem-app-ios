//
//  WalletConnectAction.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

enum WalletConnectAction: String {
    case personalSign = "personal_sign"
    case signTransaction = "eth_signTransaction"
    case sendTransaction = "eth_sendTransaction"
    case bnbSign = "bnb_sign"
    case bnbTxConfirmation = "bnb_tx_confirmation"
    case signTypedData = "eth_signTypedData"
    case signTypedDataV4 = "eth_signTypedData_v4"
    case switchChain = "wallet_switchEthereumChain"
}
