//
//  MainQRJSONPaymentParser.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct MainQRJSONPaymentParser {
    /// Supports JSON payloads such as:
    /// `{"address":"...", "chain":"polygon", "amount":"10", "memo":"..."}`
    func parse(_ value: String) -> MainQRPaymentRequest? {
        guard
            value.first == "{",
            let data = value.data(using: .utf8),
            let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return nil
        }

        let address = MainQRParserSupport.firstPayloadString(
            in: payload,
            keys: [MainQRParserConstants.PayloadKey.address]
        )?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !address.isEmpty else {
            return nil
        }

        guard
            let chainValue = MainQRParserSupport.firstPayloadString(
                in: payload,
                keys: MainQRParserConstants.jsonChainKeys
            ),
            let blockchain = MainQRParserSupport.resolveBlockchain(fromChainName: chainValue)
        else {
            return nil
        }

        guard MainQRParserSupport.isValidDestinationAddress(address, for: blockchain) else {
            return nil
        }

        let amountString = MainQRParserSupport.firstPayloadString(
            in: payload,
            keys: MainQRParserConstants.jsonAmountKeys
        )
        let amount = amountString.flatMap(MainQRParserSupport.parseDecimal)
        let memo = MainQRParserSupport.firstPayloadString(
            in: payload,
            keys: MainQRParserConstants.jsonMemoKeys
        )

        return MainQRPaymentRequest(
            blockchain: blockchain,
            destinationAddress: address,
            amount: amount,
            rawAmount: amountString,
            memo: memo,
            tokenContractAddress: nil
        )
    }
}
