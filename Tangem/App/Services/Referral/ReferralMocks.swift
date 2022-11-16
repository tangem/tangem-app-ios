//
//  ReferralMocks.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

enum ReferralMock {
    case notReferral
    case referral

    var json: String {
        switch self {
        case .notReferral:
            return """
            {
                "conditions": {
                    "award": 10,
                    "discount": 10,
                    "discountType": "percentage",
                    "touLink": "https://tangem.com/xxx.html",
                    "tokens": [
                        {
                            "id": "busdId",
                            "name": "Binance USD",
                            "symbol": "BUSD",
                            "networkId": "binance-smart-chain",
                            "contractAddress": "0x85eac5ac2f758618dfa09bdbe0cf174e7d574d5b",
                            "decimalCount": 18
                        },
                        {
                            "id": "busdId",
                            "name": "Binance USD",
                            "symbol": "BUSD",
                            "networkId": "solana",
                            "contractAddress": "0x85eac5ac2f758618dfa7654be0cf174e7d574d5b",
                            "decimalCount": 18
                        }
                    ]
                }
            }
            """
        case .referral:
            return """
            {
                "conditions": {
                    "award": 760,
                    "discount": 40,
                    "discountType": "percentage",
                    "touLink": "https://tangem.com/xxx.html",
                    "tokens": [
                        {
                            "id": "busdId",
                            "name": "Binance USD",
                            "symbol": "BUSD",
                            "networkId": "binance-smart-chain",
                            "contractAddress": "0x85eac5ac2f758618dfa09bdbe0cf174e7d574d5b",
                            "decimalCount": 18
                        },
                        {
                            "id": "busdId",
                            "name": "Binance USD",
                            "symbol": "BUSD",
                            "networkId": "solana",
                            "contractAddress": "0x85eac5ac2f758618dfa7654be0cf174e7d574d5b",
                            "decimalCount": 18
                        }
                    ]
                },
                "referral": {
                    "shareLink": "",
                    "address": "0x1dac9...39583000",
                    "promoCode": "x4JdK9",
                    "walletPurchase": 5
                }
            }
            """
        }
    }
}
