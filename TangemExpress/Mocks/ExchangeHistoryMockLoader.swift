//
//  ExchangeHistoryMockLoader.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if DEBUG
import Foundation

// [REDACTED_TODO_COMMENT]
final class ExchangeHistoryMockLoader {
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
private extension ExchangeHistoryMockLoader {
    static let page1: String = #"""
    {
      "data": [
        {
          "txId": "tx_001_finished_eth_to_usdc",
          "status": "finished",
          "provider": {
            "id": "changelly",
            "name": "Changelly",
            "iconUrl": "https://s3.eu-central-1.amazonaws.com/tangem.api/express/providers/changelly.png",
            "providerUrl": "https://changelly.com"
          },
          "from": {
            "network": "ethereum",
            "tokenId": null,
            "rawAmount": "100000000000000000",
            "decimals": 18,
            "isActual": true
          },
          "to": {
            "network": "ethereum",
            "tokenId": "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
            "rawAmount": "240500000",
            "decimals": 6,
            "isActual": true
          },
          "payinHash": "0x6f4a8c9b2e1d3f5a7c9e1b3d5f7a9c1e3b5d7f9a1c3e5b7d9f1a3c5e7b9d1f3a",
          "payoutHash": "0xa1c3e5b7d9f1a3c5e7b9d1f3a5c7e9b1d3f5a7c9e1b3d5f7a9c1e3b5d7f9a1c3",
          "externalTxId": "ext_changelly_001",
          "externalTxUrl": "https://changelly.com/track/ext_changelly_001",
          "refund": null,
          "rateType": "float",
          "createdAt": "2026-05-09T10:11:22.000Z",
          "updatedAt": "2026-05-09T10:42:00.000Z"
        },
        {
          "txId": "tx_002_finished_usdc_to_usdt",
          "status": "finished",
          "provider": {
            "id": "1inch",
            "name": "1inch",
            "iconUrl": "https://s3.eu-central-1.amazonaws.com/tangem.api/express/providers/1inch.png",
            "providerUrl": "https://1inch.io"
          },
          "from": {
            "network": "ethereum",
            "tokenId": "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
            "rawAmount": "500000000",
            "decimals": 6,
            "isActual": true
          },
          "to": {
            "network": "ethereum",
            "tokenId": "0xdac17f958d2ee523a2206206994597c13d831ec7",
            "rawAmount": "499750000",
            "decimals": 6,
            "isActual": true
          },
          "payinHash": "0xb2d4f6a8c0e2b4d6f8a0c2e4b6d8f0a2c4e6b8d0f2a4c6e8b0d2f4a6c8e0b2d4",
          "payoutHash": "0xc3e5a7b9d1f3a5c7e9b1d3f5a7c9e1b3d5f7a9c1e3b5d7f9a1c3e5b7d9f1a3c5",
          "externalTxId": "ext_1inch_002",
          "externalTxUrl": "https://etherscan.io/tx/0xc3e5a7b9d1f3a5c7e9b1d3f5a7c9e1b3d5f7a9c1e3b5d7f9a1c3e5b7d9f1a3c5",
          "refund": null,
          "rateType": "float",
          "createdAt": "2026-05-12T08:33:14.500Z",
          "updatedAt": "2026-05-12T08:36:48.000Z"
        },
        {
          "txId": "tx_003_exchanging_matic_to_eth",
          "status": "exchanging",
          "provider": {
            "id": "changenow",
            "name": "ChangeNOW",
            "iconUrl": "https://s3.eu-central-1.amazonaws.com/tangem.api/express/providers/changenow.png",
            "providerUrl": "https://changenow.io"
          },
          "from": {
            "network": "polygon-ecosystem-token",
            "tokenId": null,
            "rawAmount": "1500000000000000000000",
            "decimals": 18,
            "isActual": true
          },
          "to": {
            "network": "ethereum",
            "tokenId": null,
            "rawAmount": "350000000000000000",
            "decimals": 18,
            "isActual": false
          },
          "payinHash": "0xd4f6b8a0c2e4b6d8f0a2c4e6b8d0f2a4c6e8b0d2f4a6c8e0b2d4f6a8c0e2b4d6",
          "payoutHash": null,
          "externalTxId": "ext_changenow_003",
          "externalTxUrl": "https://changenow.io/exchange/txs/ext_changenow_003",
          "refund": null,
          "rateType": "fixed",
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
          "txId": "tx_004_refunded_eth_to_dai",
          "status": "refunded",
          "provider": {
            "id": "changelly",
            "name": "Changelly",
            "iconUrl": "https://s3.eu-central-1.amazonaws.com/tangem.api/express/providers/changelly.png",
            "providerUrl": "https://changelly.com"
          },
          "from": {
            "network": "ethereum",
            "tokenId": null,
            "rawAmount": "250000000000000000",
            "decimals": 18,
            "isActual": true
          },
          "to": {
            "network": "ethereum",
            "tokenId": "0x6b175474e89094c44da98b954eedeac495271d0f",
            "rawAmount": "0",
            "decimals": 18,
            "isActual": false
          },
          "payinHash": "0xe5a7c9b1d3f5a7c9e1b3d5f7a9c1e3b5d7f9a1c3e5b7d9f1a3c5e7b9d1f3a5c7",
          "payoutHash": null,
          "externalTxId": "ext_changelly_004",
          "externalTxUrl": "https://changelly.com/track/ext_changelly_004",
          "refund": {
            "network": "ethereum",
            "tokenId": null,
            "rawAmount": "249500000000000000",
            "decimals": 18,
            "hash": "0xf6b8c0d2e4a6b8c0d2e4f6a8b0c2d4e6f8a0b2c4d6e8f0a2b4c6d8e0f2a4b6c8"
          },
          "rateType": "float",
          "createdAt": "2026-05-15T11:08:31.000Z",
          "updatedAt": "2026-05-15T12:14:55.500Z"
        },
        {
          "txId": "tx_005_waiting_usdc_to_eth",
          "status": "waiting",
          "provider": {
            "id": "1inch",
            "name": "1inch",
            "iconUrl": "https://s3.eu-central-1.amazonaws.com/tangem.api/express/providers/1inch.png",
            "providerUrl": "https://1inch.io"
          },
          "from": {
            "network": "ethereum",
            "tokenId": "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
            "rawAmount": "1000000000",
            "decimals": 6,
            "isActual": true
          },
          "to": {
            "network": "ethereum",
            "tokenId": null,
            "rawAmount": "320000000000000000",
            "decimals": 18,
            "isActual": false
          },
          "payinHash": null,
          "payoutHash": null,
          "externalTxId": "ext_1inch_005",
          "externalTxUrl": "https://1inch.io/swap/ext_1inch_005",
          "refund": null,
          "rateType": "float",
          "createdAt": "2026-05-17T09:45:00.000Z",
          "updatedAt": "2026-05-17T09:45:00.000Z"
        },
        {
          "txId": "tx_006_finished_usdt_to_usdc",
          "status": "finished",
          "provider": {
            "id": "changenow",
            "name": "ChangeNOW",
            "iconUrl": "https://s3.eu-central-1.amazonaws.com/tangem.api/express/providers/changenow.png",
            "providerUrl": "https://changenow.io"
          },
          "from": {
            "network": "ethereum",
            "tokenId": "0xdac17f958d2ee523a2206206994597c13d831ec7",
            "rawAmount": "200000000",
            "decimals": 6,
            "isActual": true
          },
          "to": {
            "network": "ethereum",
            "tokenId": "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
            "rawAmount": "199820000",
            "decimals": 6,
            "isActual": true
          },
          "payinHash": "0xa7c9e1b3d5f7a9c1e3b5d7f9a1c3e5b7d9f1a3c5e7b9d1f3a5c7e9b1d3f5a7c9",
          "payoutHash": "0xb8d0f2a4c6e8b0d2f4a6c8e0b2d4f6a8c0e2b4d6f8a0c2e4b6d8f0a2c4e6b8d0",
          "externalTxId": "ext_changenow_006",
          "externalTxUrl": "https://changenow.io/exchange/txs/ext_changenow_006",
          "refund": null,
          "rateType": "fixed",
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
          "txId": "tx_007_failed_eth_to_wbtc",
          "status": "failed",
          "provider": {
            "id": "1inch",
            "name": "1inch",
            "iconUrl": "https://s3.eu-central-1.amazonaws.com/tangem.api/express/providers/1inch.png",
            "providerUrl": "https://1inch.io"
          },
          "from": {
            "network": "ethereum",
            "tokenId": null,
            "rawAmount": "500000000000000000",
            "decimals": 18,
            "isActual": true
          },
          "to": {
            "network": "ethereum",
            "tokenId": "0x2260fac5e5542a773aa44fbcfedf7c193bc2c599",
            "rawAmount": "0",
            "decimals": 8,
            "isActual": false
          },
          "payinHash": "0xc9e1b3d5f7a9c1e3b5d7f9a1c3e5b7d9f1a3c5e7b9d1f3a5c7e9b1d3f5a7c9e1",
          "payoutHash": null,
          "externalTxId": "ext_1inch_007",
          "externalTxUrl": "https://1inch.io/swap/ext_1inch_007",
          "refund": null,
          "rateType": "float",
          "createdAt": "2026-05-19T16:02:55.000Z",
          "updatedAt": "2026-05-19T16:18:33.125Z"
        },
        {
          "txId": "tx_008_finished_dai_to_usdc",
          "status": "finished",
          "provider": {
            "id": "changelly",
            "name": "Changelly",
            "iconUrl": "https://s3.eu-central-1.amazonaws.com/tangem.api/express/providers/changelly.png",
            "providerUrl": "https://changelly.com"
          },
          "from": {
            "network": "ethereum",
            "tokenId": "0x6b175474e89094c44da98b954eedeac495271d0f",
            "rawAmount": "750000000000000000000",
            "decimals": 18,
            "isActual": true
          },
          "to": {
            "network": "ethereum",
            "tokenId": "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
            "rawAmount": "749100000",
            "decimals": 6,
            "isActual": true
          },
          "payinHash": "0xd0e2b4d6f8a0c2e4b6d8f0a2c4e6b8d0f2a4c6e8b0d2f4a6c8e0b2d4f6a8c0e2",
          "payoutHash": "0xe1b3d5f7a9c1e3b5d7f9a1c3e5b7d9f1a3c5e7b9d1f3a5c7e9b1d3f5a7c9e1b3",
          "externalTxId": "ext_changelly_008",
          "externalTxUrl": "https://changelly.com/track/ext_changelly_008",
          "refund": null,
          "rateType": "float",
          "createdAt": "2026-05-20T07:25:14.000Z",
          "updatedAt": "2026-05-20T07:29:01.500Z"
        },
        {
          "txId": "tx_009_finished_eth_to_usdc",
          "status": "finished",
          "provider": {
            "id": "changenow",
            "name": "ChangeNOW",
            "iconUrl": "https://s3.eu-central-1.amazonaws.com/tangem.api/express/providers/changenow.png",
            "providerUrl": "https://changenow.io"
          },
          "from": {
            "network": "ethereum",
            "tokenId": null,
            "rawAmount": "75000000000000000",
            "decimals": 18,
            "isActual": true
          },
          "to": {
            "network": "ethereum",
            "tokenId": "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
            "rawAmount": "180400000",
            "decimals": 6,
            "isActual": true
          },
          "payinHash": "0xf2a4c6e8b0d2f4a6c8e0b2d4f6a8c0e2b4d6f8a0c2e4b6d8f0a2c4e6b8d0f2a4",
          "payoutHash": "0xa3c5e7b9d1f3a5c7e9b1d3f5a7c9e1b3d5f7a9c1e3b5d7f9a1c3e5b7d9f1a3c5",
          "externalTxId": "ext_changenow_009",
          "externalTxUrl": "https://changenow.io/exchange/txs/ext_changenow_009",
          "refund": null,
          "rateType": "fixed",
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
