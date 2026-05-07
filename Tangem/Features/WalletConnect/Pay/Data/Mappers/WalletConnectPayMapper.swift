//
//  WalletConnectPayMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import ReownWalletKit
import YttriumWrapper

enum WalletConnectPayMapper {
    static func map(_ response: PaymentOptionsResponse) -> WalletConnectPayOptionsResponse {
        WalletConnectPayOptionsResponse(
            paymentId: response.paymentId,
            info: response.info.map(map),
            options: response.options.map(map),
            collectData: response.collectData.map(map)
        )
    }

    static func map(_ actions: [YttriumWrapper.Action]) -> [WalletConnectPayAction] {
        actions.map(map)
    }

    static func map(_ response: ConfirmPaymentResultResponse) -> WalletConnectPayResult {
        WalletConnectPayResult(
            status: map(response.status),
            isFinal: response.isFinal,
            pollInMs: response.pollInMs,
            info: response.info.map(map)
        )
    }

    private static func map(_ info: PaymentInfo) -> WalletConnectPayInfo {
        WalletConnectPayInfo(
            status: map(info.status),
            amount: map(info.amount),
            expiresAt: info.expiresAt,
            merchant: WalletConnectPayMerchant(name: info.merchant.name, iconUrl: info.merchant.iconUrl)
        )
    }

    private static func map(_ option: PaymentOption) -> WalletConnectPayOption {
        WalletConnectPayOption(
            id: option.id,
            account: option.account,
            amount: map(option.amount),
            etaS: option.etaS,
            expiresAt: option.expiresAt,
            actions: option.actions.map(map),
            collectData: option.collectData.map(map)
        )
    }

    private static func map(_ amount: PayAmount) -> WalletConnectPayAmount {
        WalletConnectPayAmount(
            unit: amount.unit,
            value: amount.value,
            display: WalletConnectPayAmountDisplay(
                assetSymbol: amount.display.assetSymbol,
                assetName: amount.display.assetName,
                decimals: Int(amount.display.decimals),
                iconUrl: amount.display.iconUrl,
                networkIconUrl: amount.display.networkIconUrl,
                networkName: amount.display.networkName
            )
        )
    }

    private static func map(_ action: YttriumWrapper.Action) -> WalletConnectPayAction {
        WalletConnectPayAction(walletRpc: WalletConnectPayWalletRPC(
            chainId: action.walletRpc.chainId,
            method: action.walletRpc.method,
            params: action.walletRpc.params
        ))
    }

    private static func map(_ collectData: CollectDataAction) -> WalletConnectPayCollectData {
        WalletConnectPayCollectData(url: collectData.url, schema: collectData.schema)
    }

    private static func map(_ info: PaymentResultInfo) -> WalletConnectPayResultInfo {
        WalletConnectPayResultInfo(txId: info.txId, optionAmount: map(info.optionAmount))
    }

    private static func map(_ status: PaymentStatus) -> WalletConnectPayStatus {
        switch status {
        case .requiresAction:
            return .requiresAction
        case .processing:
            return .processing
        case .succeeded:
            return .succeeded
        case .failed:
            return .failed
        case .expired:
            return .expired
        case .cancelled:
            return .cancelled
        }
    }
}
