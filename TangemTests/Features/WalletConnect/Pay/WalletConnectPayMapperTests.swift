//
//  WalletConnectPayMapperTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import ReownWalletKit
@testable import Tangem

final class WalletConnectPayMapperTests: XCTestCase {
    func testMapPaymentOptionsResponse() {
        let amount = PayAmount(
            unit: "USDC",
            value: "1000000",
            display: AmountDisplay(
                assetSymbol: "USDC",
                assetName: "USD Coin",
                decimals: 6,
                iconUrl: "https://example.com/usdc.png",
                networkIconUrl: "https://example.com/base.png",
                networkName: "Base"
            )
        )
        let action = Action(walletRpc: WalletRpcAction(
            chainId: "eip155:8453",
            method: "eth_sendTransaction",
            params: "[]"
        ))
        let collectData = CollectDataAction(fields: [], url: "https://pay.walletconnect.com/ic", schema: "{}")
        let response = PaymentOptionsResponse(
            paymentId: "pay_123",
            info: PaymentInfo(
                status: .requiresAction,
                amount: amount,
                expiresAt: 100,
                merchant: MerchantInfo(name: "Merchant", iconUrl: nil),
                buyer: nil
            ),
            options: [
                PaymentOption(
                    id: "option_1",
                    account: "eip155:8453:0x0000000000000000000000000000000000000001",
                    amount: amount,
                    etaS: 30,
                    expiresAt: nil,
                    actions: [action],
                    collectData: collectData
                ),
            ],
            collectData: collectData
        )

        let mapped = WalletConnectPayMapper.map(response)

        XCTAssertEqual(mapped.paymentId, "pay_123")
        XCTAssertEqual(mapped.info?.merchant.name, "Merchant")
        XCTAssertEqual(mapped.options.first?.amount.display.assetSymbol, "USDC")
        XCTAssertEqual(mapped.options.first?.actions.first?.walletRpc.chainId, "eip155:8453")
        XCTAssertEqual(mapped.options.first?.collectData?.url, "https://pay.walletconnect.com/ic")
    }
}
