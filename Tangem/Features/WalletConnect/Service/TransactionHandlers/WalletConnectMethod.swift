//
//  WalletConnectMethod.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

enum WalletConnectMethod: String {
    case personalSign = "personal_sign"

    // MARK: - ETH

    case addChain = "wallet_addEthereumChain"
    case switchChain = "wallet_switchEthereumChain"
    case signTransaction = "eth_signTransaction"
    case sendTransaction = "eth_sendTransaction"
    case signTypedData = "eth_signTypedData"
    case signTypedDataV4 = "eth_signTypedData_v4"

    // MARK: - BNB

    case bnbSign = "bnb_sign"
    case bnbTxConfirmation = "bnb_tx_confirmation"

    // MARK: - SOL

    case solanaSignTransaction = "solana_signTransaction"
    case solanaSignMessage = "solana_signMessage"
    case solanaSignAllTransactions = "solana_signAllTransactions"

    // MARK: - BTC

    case sendTransfer
    case getAccountAddresses
    case signPsbt
    case signMessage

    // MARK: - Hedera (HIP-820)

    case hederaSignAndExecuteTransaction = "hedera_signAndExecuteTransaction"
    case hederaSignTransaction = "hedera_signTransaction"
    case hederaSignMessage = "hedera_signMessage"
    case hederaGetNodeAddresses = "hedera_getNodeAddresses"

    var trimmedPrefixValue: String {
        switch self {
        case .personalSign:
            "personalSign"
        case .switchChain:
            "switchChain"
        case .addChain:
            "addChain"
        case .signTransaction:
            "signTransaction"
        case .sendTransaction:
            "sendTransaction"
        case .signTypedData:
            "signTypedData"
        case .signTypedDataV4:
            "signTypedDataV4"
        case .bnbSign:
            "sign"
        case .bnbTxConfirmation:
            "txConfirmation"
        case .solanaSignTransaction:
            "signTransaction"
        case .solanaSignMessage:
            "signMessage"
        case .solanaSignAllTransactions:
            "signAllTransactions"
        case .sendTransfer, .getAccountAddresses, .signPsbt, .signMessage:
            rawValue
        case .hederaSignAndExecuteTransaction:
            "signAndExecuteTransaction"
        case .hederaSignTransaction:
            "signTransaction"
        case .hederaSignMessage:
            "signMessage"
        case .hederaGetNodeAddresses:
            "getNodeAddresses"
        }
    }
}

extension WalletConnectMethod {
    var isSendTransaction: Bool {
        switch self {
        case .sendTransaction, .sendTransfer, .hederaSignAndExecuteTransaction:
            true
        default:
            false
        }
    }
}
