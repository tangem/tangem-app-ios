//
//  WalletConnectPayModels.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct WalletConnectPayOptionsResponse: Equatable {
    let paymentId: String
    let info: WalletConnectPayInfo?
    let options: [WalletConnectPayOption]
    let collectData: WalletConnectPayCollectData?
}

struct WalletConnectPayInfo: Equatable {
    let status: WalletConnectPayStatus
    let amount: WalletConnectPayAmount
    let expiresAt: Int64
    let merchant: WalletConnectPayMerchant
}

struct WalletConnectPayMerchant: Equatable {
    let name: String
    let iconUrl: String?
}

struct WalletConnectPayOption: Identifiable, Equatable {
    let id: String
    let account: String
    let amount: WalletConnectPayAmount
    let etaS: Int64
    let expiresAt: Int64?
    let actions: [WalletConnectPayAction]
    let collectData: WalletConnectPayCollectData?
}

struct WalletConnectPayAmount: Equatable {
    let unit: String
    let value: String
    let display: WalletConnectPayAmountDisplay
}

struct WalletConnectPayAmountDisplay: Equatable {
    let assetSymbol: String
    let assetName: String
    let decimals: Int
    let iconUrl: String?
    let networkIconUrl: String?
    let networkName: String?
}

struct WalletConnectPayAction: Equatable {
    let walletRpc: WalletConnectPayWalletRPC
}

struct WalletConnectPayWalletRPC: Equatable {
    let chainId: String
    let method: String
    let params: String
}

struct WalletConnectPayCollectData: Equatable {
    let url: String?
    let schema: String?
}

struct WalletConnectPayResult: Equatable {
    let status: WalletConnectPayStatus
    let isFinal: Bool
    let pollInMs: Int64?
    let info: WalletConnectPayResultInfo?
}

struct WalletConnectPayResultInfo: Equatable {
    let txId: String
    let optionAmount: WalletConnectPayAmount
}

enum WalletConnectPayStatus: Equatable {
    case requiresAction
    case processing
    case succeeded
    case failed
    case expired
    case cancelled
}
