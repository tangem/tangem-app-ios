//
//  WalletConnectPayService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import ReownWalletKit

protocol WalletConnectPayService {
    func getPaymentOptions(link: WalletConnectPayLink, accounts: [WalletConnectAccount]) async throws -> WalletConnectPayOptionsResponse
    func getRequiredActions(paymentId: String, optionId: String) async throws -> [WalletConnectPayAction]
    func confirmPayment(paymentId: String, optionId: String, signatures: [String]) async throws -> WalletConnectPayResult
}

struct ReownWalletConnectPayService: WalletConnectPayService {
    private let walletKitClient: ReownWalletKit.WalletKitClient

    init(walletKitClient: ReownWalletKit.WalletKitClient) {
        self.walletKitClient = walletKitClient
    }

    func getPaymentOptions(
        link: WalletConnectPayLink,
        accounts: [WalletConnectAccount]
    ) async throws -> WalletConnectPayOptionsResponse {
        let response = try await walletKitClient.Pay.getPaymentOptions(
            paymentLink: link.rawValue,
            accounts: accounts.map { "\($0.namespace):\($0.reference):\($0.address)" },
            includePaymentInfo: true
        )

        return WalletConnectPayMapper.map(response)
    }

    func getRequiredActions(paymentId: String, optionId: String) async throws -> [WalletConnectPayAction] {
        let actions = try await walletKitClient.Pay.getRequiredPaymentActions(
            paymentId: paymentId,
            optionId: optionId
        )

        return WalletConnectPayMapper.map(actions)
    }

    func confirmPayment(paymentId: String, optionId: String, signatures: [String]) async throws -> WalletConnectPayResult {
        let response = try await walletKitClient.Pay.confirmPayment(
            paymentId: paymentId,
            optionId: optionId,
            signatures: signatures,
            maxPollMs: 60000
        )

        return WalletConnectPayMapper.map(response)
    }
}
