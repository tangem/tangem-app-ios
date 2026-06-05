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
    static func data(forRequest request: ExpressDTO.Swap.History.Request) -> Data {
        let payload: String

        switch request.afterCursor {
        case nil:
            // According to the API contract, the first page is requested with no `afterCursor`
            payload = page1
        case .some("p2"):
            payload = page2
        case .some("p3"):
            payload = page3
        default:
            preconditionFailure("Invalid cursor: \(String(describing: request.afterCursor))")
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
      "items": [
        {
          "txId": "tx_001_finished_eth_to_usdc",
          "providerId": "changelly",
          "fromAddress": "0x742d35Cc6634C0532925a3b844Bc454e4438f44e",
          "payinAddress": "0x1111111111111111111111111111111111111111",
          "payoutAddress": "0x742d35Cc6634C0532925a3b844Bc454e4438f44e",
          "rateType": "float",
          "status": "finished",
          "externalTxId": "ext_changelly_001",
          "externalTxStatus": "finished",
          "externalTxUrl": "https://changelly.com/track/ext_changelly_001",
          "payinHash": "0x6f4a8c9b2e1d3f5a7c9e1b3d5f7a9c1e3b5d7f9a1c3e5b7d9f1a3c5e7b9d1f3a",
          "payoutHash": "0xa1c3e5b7d9f1a3c5e7b9d1f3a5c7e9b1d3f5a7c9e1b3d5f7a9c1e3b5d7f9a1c3",
          "createdAt": "2026-05-09T10:11:22.000Z",
          "averageDuration": 1800,
          "fromContractAddress": "",
          "fromNetwork": "ethereum",
          "fromDecimals": 18,
          "fromAmount": "100000000000000000",
          "toContractAddress": "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
          "toNetwork": "ethereum",
          "toDecimals": 6,
          "toAmount": "240500000"
        },
        {
          "txId": "tx_002_finished_usdc_to_usdt",
          "providerId": "1inch",
          "fromAddress": "0x742d35Cc6634C0532925a3b844Bc454e4438f44e",
          "payinAddress": "0x1111111111111111111111111111111111111111",
          "payoutAddress": "0x742d35Cc6634C0532925a3b844Bc454e4438f44e",
          "rateType": "float",
          "status": "finished",
          "externalTxId": "ext_1inch_002",
          "externalTxUrl": "https://etherscan.io/tx/0xc3e5a7b9d1f3a5c7e9b1d3f5a7c9e1b3d5f7a9c1e3b5d7f9a1c3e5b7d9f1a3c5",
          "payinHash": "0xb2d4f6a8c0e2b4d6f8a0c2e4b6d8f0a2c4e6b8d0f2a4c6e8b0d2f4a6c8e0b2d4",
          "payoutHash": "0xc3e5a7b9d1f3a5c7e9b1d3f5a7c9e1b3d5f7a9c1e3b5d7f9a1c3e5b7d9f1a3c5",
          "createdAt": "2026-05-12T08:33:14.500Z",
          "fromContractAddress": "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
          "fromNetwork": "ethereum",
          "fromDecimals": 6,
          "fromAmount": "500000000",
          "toContractAddress": "0xdac17f958d2ee523a2206206994597c13d831ec7",
          "toNetwork": "ethereum",
          "toDecimals": 6,
          "toAmount": "499750000"
        },
        {
          "txId": "tx_003_exchanging_matic_to_eth",
          "providerId": "changenow",
          "fromAddress": "0x742d35Cc6634C0532925a3b844Bc454e4438f44e",
          "payinAddress": "0x1111111111111111111111111111111111111111",
          "payoutAddress": "0x742d35Cc6634C0532925a3b844Bc454e4438f44e",
          "rateType": "fixed",
          "status": "exchanging",
          "externalTxId": "ext_changenow_003",
          "externalTxStatus": "exchanging",
          "externalTxUrl": "https://changenow.io/exchange/txs/ext_changenow_003",
          "payinHash": "0xd4f6b8a0c2e4b6d8f0a2c4e6b8d0f2a4c6e8b0d2f4a6c8e0b2d4f6a8c0e2b4d6",
          "createdAt": "2026-05-14T15:22:09.250Z",
          "fromContractAddress": "",
          "fromNetwork": "polygon-ecosystem-token",
          "fromDecimals": 18,
          "fromAmount": "1500000000000000000000",
          "toContractAddress": "",
          "toNetwork": "ethereum",
          "toDecimals": 18,
          "toAmount": "350000000000000000"
        }
      ],
      "pagination": {
        "endCursor": "p2",
        "startDeltaCursor": "delta_seed_2026-05-09T10:10:22.000Z",
        "hasMore": true
      }
    }
    """#

    static let page2: String = #"""
    {
      "items": [
        {
          "txId": "tx_004_refunded_eth_to_dai",
          "providerId": "changelly",
          "fromAddress": "0x742d35Cc6634C0532925a3b844Bc454e4438f44e",
          "payinAddress": "0x1111111111111111111111111111111111111111",
          "payoutAddress": "0x742d35Cc6634C0532925a3b844Bc454e4438f44e",
          "refundAddress": "0x742d35Cc6634C0532925a3b844Bc454e4438f44e",
          "rateType": "float",
          "status": "refunded",
          "externalTxId": "ext_changelly_004",
          "externalTxUrl": "https://changelly.com/track/ext_changelly_004",
          "payinHash": "0xe5a7c9b1d3f5a7c9e1b3d5f7a9c1e3b5d7f9a1c3e5b7d9f1a3c5e7b9d1f3a5c7",
          "refundNetwork": "ethereum",
          "refundContractAddress": "",
          "createdAt": "2026-05-15T11:08:31.000Z",
          "fromContractAddress": "",
          "fromNetwork": "ethereum",
          "fromDecimals": 18,
          "fromAmount": "250000000000000000",
          "toContractAddress": "0x6b175474e89094c44da98b954eedeac495271d0f",
          "toNetwork": "ethereum",
          "toDecimals": 18,
          "toAmount": "0"
        },
        {
          "txId": "tx_005_waiting_usdc_to_eth",
          "providerId": "1inch",
          "fromAddress": "0x742d35Cc6634C0532925a3b844Bc454e4438f44e",
          "payinAddress": "0x1111111111111111111111111111111111111111",
          "payoutAddress": "0x742d35Cc6634C0532925a3b844Bc454e4438f44e",
          "rateType": "float",
          "status": "waiting",
          "externalTxId": "ext_1inch_005",
          "externalTxUrl": "https://1inch.io/swap/ext_1inch_005",
          "createdAt": "2026-05-17T09:45:00.000Z",
          "payTill": "2026-05-17T10:15:00.000Z",
          "fromContractAddress": "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
          "fromNetwork": "ethereum",
          "fromDecimals": 6,
          "fromAmount": "1000000000",
          "toContractAddress": "",
          "toNetwork": "ethereum",
          "toDecimals": 18,
          "toAmount": "320000000000000000"
        },
        {
          "txId": "tx_006_finished_usdt_to_usdc",
          "providerId": "changenow",
          "fromAddress": "0x742d35Cc6634C0532925a3b844Bc454e4438f44e",
          "payinAddress": "0x1111111111111111111111111111111111111111",
          "payoutAddress": "0x742d35Cc6634C0532925a3b844Bc454e4438f44e",
          "rateType": "fixed",
          "status": "finished",
          "externalTxId": "ext_changenow_006",
          "externalTxStatus": "finished",
          "externalTxUrl": "https://changenow.io/exchange/txs/ext_changenow_006",
          "payinHash": "0xa7c9e1b3d5f7a9c1e3b5d7f9a1c3e5b7d9f1a3c5e7b9d1f3a5c7e9b1d3f5a7c9",
          "payoutHash": "0xb8d0f2a4c6e8b0d2f4a6c8e0b2d4f6a8c0e2b4d6f8a0c2e4b6d8f0a2c4e6b8d0",
          "createdAt": "2026-05-18T13:51:42.750Z",
          "fromContractAddress": "0xdac17f958d2ee523a2206206994597c13d831ec7",
          "fromNetwork": "ethereum",
          "fromDecimals": 6,
          "fromAmount": "200000000",
          "toContractAddress": "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
          "toNetwork": "ethereum",
          "toDecimals": 6,
          "toAmount": "199820000"
        }
      ],
      "pagination": {
        "endCursor": "p3",
        "startDeltaCursor": null,
        "hasMore": true
      }
    }
    """#

    static let page3: String = #"""
    {
      "items": [
        {
          "txId": "tx_007_failed_eth_to_wbtc",
          "providerId": "1inch",
          "fromAddress": "0x742d35Cc6634C0532925a3b844Bc454e4438f44e",
          "payinAddress": "0x1111111111111111111111111111111111111111",
          "payoutAddress": "0x742d35Cc6634C0532925a3b844Bc454e4438f44e",
          "rateType": "float",
          "status": "failed",
          "externalTxId": "ext_1inch_007",
          "externalTxUrl": "https://1inch.io/swap/ext_1inch_007",
          "payinHash": "0xc9e1b3d5f7a9c1e3b5d7f9a1c3e5b7d9f1a3c5e7b9d1f3a5c7e9b1d3f5a7c9e1",
          "createdAt": "2026-05-19T16:02:55.000Z",
          "fromContractAddress": "",
          "fromNetwork": "ethereum",
          "fromDecimals": 18,
          "fromAmount": "500000000000000000",
          "toContractAddress": "0x2260fac5e5542a773aa44fbcfedf7c193bc2c599",
          "toNetwork": "ethereum",
          "toDecimals": 8,
          "toAmount": "0"
        },
        {
          "txId": "tx_008_finished_dai_to_usdc",
          "providerId": "changelly",
          "fromAddress": "0x742d35Cc6634C0532925a3b844Bc454e4438f44e",
          "payinAddress": "0x1111111111111111111111111111111111111111",
          "payoutAddress": "0x742d35Cc6634C0532925a3b844Bc454e4438f44e",
          "rateType": "float",
          "status": "finished",
          "externalTxId": "ext_changelly_008",
          "externalTxStatus": "finished",
          "externalTxUrl": "https://changelly.com/track/ext_changelly_008",
          "payinHash": "0xd0e2b4d6f8a0c2e4b6d8f0a2c4e6b8d0f2a4c6e8b0d2f4a6c8e0b2d4f6a8c0e2",
          "payoutHash": "0xe1b3d5f7a9c1e3b5d7f9a1c3e5b7d9f1a3c5e7b9d1f3a5c7e9b1d3f5a7c9e1b3",
          "createdAt": "2026-05-20T07:25:14.000Z",
          "fromContractAddress": "0x6b175474e89094c44da98b954eedeac495271d0f",
          "fromNetwork": "ethereum",
          "fromDecimals": 18,
          "fromAmount": "750000000000000000000",
          "toContractAddress": "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
          "toNetwork": "ethereum",
          "toDecimals": 6,
          "toAmount": "749100000"
        },
        {
          "txId": "tx_009_finished_eth_to_usdc",
          "providerId": "changenow",
          "fromAddress": "0x742d35Cc6634C0532925a3b844Bc454e4438f44e",
          "payinAddress": "0x1111111111111111111111111111111111111111",
          "payoutAddress": "0x742d35Cc6634C0532925a3b844Bc454e4438f44e",
          "rateType": "fixed",
          "status": "finished",
          "externalTxId": "ext_changenow_009",
          "externalTxStatus": "finished",
          "externalTxUrl": "https://changenow.io/exchange/txs/ext_changenow_009",
          "payinHash": "0xf2a4c6e8b0d2f4a6c8e0b2d4f6a8c0e2b4d6f8a0c2e4b6d8f0a2c4e6b8d0f2a4",
          "payoutHash": "0xa3c5e7b9d1f3a5c7e9b1d3f5a7c9e1b3d5f7a9c1e3b5d7f9a1c3e5b7d9f1a3c5",
          "createdAt": "2026-05-21T12:08:30.000Z",
          "fromContractAddress": "",
          "fromNetwork": "ethereum",
          "fromDecimals": 18,
          "fromAmount": "75000000000000000",
          "toContractAddress": "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
          "toNetwork": "ethereum",
          "toDecimals": 6,
          "toAmount": "180400000"
        }
      ],
      "pagination": {
        "endCursor": null,
        "startDeltaCursor": null,
        "hasMore": false
      }
    }
    """#
}
#endif // DEBUG
