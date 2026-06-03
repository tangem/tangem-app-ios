//
//  OnrampHistoryMockLoader.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if DEBUG
import Foundation

// [REDACTED_TODO_COMMENT]
final class OnrampHistoryMockLoader {
    static func data(forRequest request: ExpressDTO.HistoryRequest) -> Data {
        let cursor = request.cursor?.value as? String
        let payload: String

        switch cursor {
        case nil:
            // According to the API contract, the initial request must have a null cursor
            payload = page1
        case .some("p2"):
            payload = page2
        case .some("p3"):
            payload = page3
        default:
            preconditionFailure("Invalid cursor: \(String(describing: cursor))")
        }

        return Data(payload.utf8)
    }

    private init() {}
}

// MARK: - Page payloads

/// Using inlined payloads instead of bundled JSON resources because Xcode's `EXCLUDED_SOURCE_FILE_NAMES`
/// doesn't reliably filter bundle resources
private extension OnrampHistoryMockLoader {
    static let page1: String = #"""
    {
      "data": [
        {
          "txId": "tx_001_finished_usd_to_eth",
          "status": "finished",
          "provider": {
            "id": "mercuryo",
            "name": "Mercuryo",
            "iconUrl": "https://s3.eu-central-1.amazonaws.com/tangem.api/express/providers/mercuryo.png",
            "providerUrl": "https://mercuryo.io"
          },
          "from": {
            "currencyCode": "USD",
            "amount": "120.00"
          },
          "to": {
            "network": "ethereum",
            "tokenId": null,
            "expectedRawAmount": "50000000000000000",
            "actualRawAmount": "49850000000000000",
            "decimals": 18
          },
          "payoutHash": "0x6f4a8c9b2e1d3f5a7c9e1b3d5f7a9c1e3b5d7f9a1c3e5b7d9f1a3c5e7b9d1f3a",
          "externalTxId": "ext_mercuryo_001",
          "externalTxUrl": "https://mercuryo.io/transactions/ext_mercuryo_001",
          "refund": null,
          "rate": {
            "atCreate": "2400.00",
            "atFinish": "2398.50"
          },
          "failReason": null,
          "createdAt": "2026-05-09T10:11:22.000Z",
          "updatedAt": "2026-05-09T10:42:00.000Z"
        },
        {
          "txId": "tx_002_finished_eur_to_usdc",
          "status": "finished",
          "provider": {
            "id": "moonpay",
            "name": "MoonPay",
            "iconUrl": "https://s3.eu-central-1.amazonaws.com/tangem.api/express/providers/moonpay.png",
            "providerUrl": "https://moonpay.com"
          },
          "from": {
            "currencyCode": "EUR",
            "amount": "100.00"
          },
          "to": {
            "network": "ethereum",
            "tokenId": "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
            "expectedRawAmount": "108000000",
            "actualRawAmount": "107900000",
            "decimals": 6
          },
          "payoutHash": "0xb2d4f6a8c0e2b4d6f8a0c2e4b6d8f0a2c4e6b8d0f2a4c6e8b0d2f4a6c8e0b2d4",
          "externalTxId": "ext_moonpay_002",
          "externalTxUrl": "https://moonpay.com/transaction_receipt?transactionId=ext_moonpay_002",
          "refund": null,
          "rate": {
            "atCreate": "1.08",
            "atFinish": "1.079"
          },
          "failReason": null,
          "createdAt": "2026-05-12T08:33:14.500Z",
          "updatedAt": "2026-05-12T08:36:48.000Z"
        },
        {
          "txId": "tx_003_payment_processing_gbp_to_btc",
          "status": "payment-processing",
          "provider": {
            "id": "banxa",
            "name": "Banxa",
            "iconUrl": "https://s3.eu-central-1.amazonaws.com/tangem.api/express/providers/banxa.png",
            "providerUrl": "https://banxa.com"
          },
          "from": {
            "currencyCode": "GBP",
            "amount": "200.00"
          },
          "to": {
            "network": "bitcoin",
            "tokenId": null,
            "expectedRawAmount": "400000",
            "actualRawAmount": null,
            "decimals": 8
          },
          "payoutHash": null,
          "externalTxId": "ext_banxa_003",
          "externalTxUrl": "https://banxa.com/status?id=ext_banxa_003",
          "refund": null,
          "rate": {
            "atCreate": "50000.00",
            "atFinish": null
          },
          "failReason": null,
          "createdAt": "2026-05-14T15:22:09.250Z",
          "updatedAt": "2026-05-14T15:25:11.000Z"
        }
      ],
      "nextCursor": "p2",
      "hasMore": true
    }
    """#

    static let page2: String = #"""
    {
      "data": [
        {
          "txId": "tx_004_refunded_usd_to_sol",
          "status": "refunded",
          "provider": {
            "id": "mercuryo",
            "name": "Mercuryo",
            "iconUrl": "https://s3.eu-central-1.amazonaws.com/tangem.api/express/providers/mercuryo.png",
            "providerUrl": "https://mercuryo.io"
          },
          "from": {
            "currencyCode": "USD",
            "amount": "150.00"
          },
          "to": {
            "network": "solana",
            "tokenId": null,
            "expectedRawAmount": "1000000000",
            "actualRawAmount": null,
            "decimals": 9
          },
          "payoutHash": null,
          "externalTxId": "ext_mercuryo_004",
          "externalTxUrl": "https://mercuryo.io/transactions/ext_mercuryo_004",
          "refund": {
            "network": "ethereum",
            "tokenId": "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
            "rawAmount": "149000000",
            "decimals": 6,
            "hash": "0xf6b8c0d2e4a6b8c0d2e4f6a8b0c2d4e6f8a0b2c4d6e8f0a2b4c6d8e0f2a4b6c8"
          },
          "rate": {
            "atCreate": "150.00",
            "atFinish": null
          },
          "failReason": null,
          "createdAt": "2026-05-15T11:08:31.000Z",
          "updatedAt": "2026-05-15T12:14:55.500Z"
        },
        {
          "txId": "tx_005_waiting_for_payment_eur_to_eth",
          "status": "waiting-for-payment",
          "provider": {
            "id": "moonpay",
            "name": "MoonPay",
            "iconUrl": "https://s3.eu-central-1.amazonaws.com/tangem.api/express/providers/moonpay.png",
            "providerUrl": "https://moonpay.com"
          },
          "from": {
            "currencyCode": "EUR",
            "amount": "250.00"
          },
          "to": {
            "network": "ethereum",
            "tokenId": null,
            "expectedRawAmount": "100000000000000000",
            "actualRawAmount": null,
            "decimals": 18
          },
          "payoutHash": null,
          "externalTxId": "ext_moonpay_005",
          "externalTxUrl": "https://moonpay.com/transaction_receipt?transactionId=ext_moonpay_005",
          "refund": null,
          "rate": {
            "atCreate": "2410.00",
            "atFinish": null
          },
          "failReason": null,
          "createdAt": "2026-05-17T09:45:00.000Z",
          "updatedAt": "2026-05-17T09:45:00.000Z"
        },
        {
          "txId": "tx_006_finished_usd_to_usdt",
          "status": "finished",
          "provider": {
            "id": "banxa",
            "name": "Banxa",
            "iconUrl": "https://s3.eu-central-1.amazonaws.com/tangem.api/express/providers/banxa.png",
            "providerUrl": "https://banxa.com"
          },
          "from": {
            "currencyCode": "USD",
            "amount": "80.00"
          },
          "to": {
            "network": "ethereum",
            "tokenId": "0xdac17f958d2ee523a2206206994597c13d831ec7",
            "expectedRawAmount": "79800000",
            "actualRawAmount": "79800000",
            "decimals": 6
          },
          "payoutHash": "0xa7c9e1b3d5f7a9c1e3b5d7f9a1c3e5b7d9f1a3c5e7b9d1f3a5c7e9b1d3f5a7c9",
          "externalTxId": "ext_banxa_006",
          "externalTxUrl": "https://banxa.com/status?id=ext_banxa_006",
          "refund": null,
          "rate": {
            "atCreate": "1.00",
            "atFinish": "1.00"
          },
          "failReason": null,
          "createdAt": "2026-05-18T13:51:42.750Z",
          "updatedAt": "2026-05-18T13:55:08.250Z"
        }
      ],
      "nextCursor": "p3",
      "hasMore": true
    }
    """#

    static let page3: String = #"""
    {
      "data": [
        {
          "txId": "tx_007_failed_usd_to_btc",
          "status": "failed",
          "provider": {
            "id": "moonpay",
            "name": "MoonPay",
            "iconUrl": "https://s3.eu-central-1.amazonaws.com/tangem.api/express/providers/moonpay.png",
            "providerUrl": "https://moonpay.com"
          },
          "from": {
            "currencyCode": "USD",
            "amount": "100.00"
          },
          "to": {
            "network": "bitcoin",
            "tokenId": null,
            "expectedRawAmount": "200000",
            "actualRawAmount": null,
            "decimals": 8
          },
          "payoutHash": null,
          "externalTxId": "ext_moonpay_007",
          "externalTxUrl": "https://moonpay.com/transaction_receipt?transactionId=ext_moonpay_007",
          "refund": null,
          "rate": {
            "atCreate": "50000.00",
            "atFinish": null
          },
          "failReason": "Payment declined by the card issuer",
          "createdAt": "2026-05-19T16:02:55.000Z",
          "updatedAt": "2026-05-19T16:18:33.125Z"
        },
        {
          "txId": "tx_008_finished_gbp_to_eth",
          "status": "finished",
          "provider": {
            "id": "mercuryo",
            "name": "Mercuryo",
            "iconUrl": "https://s3.eu-central-1.amazonaws.com/tangem.api/express/providers/mercuryo.png",
            "providerUrl": "https://mercuryo.io"
          },
          "from": {
            "currencyCode": "GBP",
            "amount": "175.00"
          },
          "to": {
            "network": "ethereum",
            "tokenId": null,
            "expectedRawAmount": "90000000000000000",
            "actualRawAmount": "89700000000000000",
            "decimals": 18
          },
          "payoutHash": "0xd0e2b4d6f8a0c2e4b6d8f0a2c4e6b8d0f2a4c6e8b0d2f4a6c8e0b2d4f6a8c0e2",
          "externalTxId": "ext_mercuryo_008",
          "externalTxUrl": "https://mercuryo.io/transactions/ext_mercuryo_008",
          "refund": null,
          "rate": {
            "atCreate": "2380.00",
            "atFinish": "2378.00"
          },
          "failReason": null,
          "createdAt": "2026-05-20T07:25:14.000Z",
          "updatedAt": "2026-05-20T07:29:01.500Z"
        },
        {
          "txId": "tx_009_finished_eur_to_matic",
          "status": "finished",
          "provider": {
            "id": "banxa",
            "name": "Banxa",
            "iconUrl": "https://s3.eu-central-1.amazonaws.com/tangem.api/express/providers/banxa.png",
            "providerUrl": "https://banxa.com"
          },
          "from": {
            "currencyCode": "EUR",
            "amount": "90.50"
          },
          "to": {
            "network": "polygon-ecosystem-token",
            "tokenId": null,
            "expectedRawAmount": "125000000000000000000",
            "actualRawAmount": "124800000000000000000",
            "decimals": 18
          },
          "payoutHash": "0xf2a4c6e8b0d2f4a6c8e0b2d4f6a8c0e2b4d6f8a0c2e4b6d8f0a2c4e6b8d0f2a4",
          "externalTxId": "ext_banxa_009",
          "externalTxUrl": "https://banxa.com/status?id=ext_banxa_009",
          "refund": null,
          "rate": {
            "atCreate": "0.72",
            "atFinish": "0.724"
          },
          "failReason": null,
          "createdAt": "2026-05-21T12:08:30.000Z",
          "updatedAt": "2026-05-21T12:12:47.875Z"
        }
      ],
      "nextCursor": null,
      "hasMore": false
    }
    """#
}
#endif // DEBUG
