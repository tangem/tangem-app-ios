//
//  ABIValueNegativeUIntTests.swift
//  BlockchainSdkTests
//
//  Created by Dean Rie on 28.09.2026.
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import Testing
@testable import BlockchainSdk

struct ABIValueNegativeUIntTests {
    @Test(arguments: [-1, Int.min, -42])
    func negativeIntegerInUnsignedFieldThrowsInsteadOfTrapping(value: Int) {
        #expect(throws: ABIError.invalidArgumentType) {
            try ABIValue(value, type: .uint(bits: 256))
        }
    }

    @Test(arguments: [0, 1, Int.max])
    func nonNegativeIntegerInUnsignedFieldIsAccepted(value: Int) throws {
        let abiValue = try ABIValue(value, type: .uint(bits: 256))
        #expect(abiValue == .uint(bits: 256, BigUInt(value)))
    }

    /// End-to-end: a dApp `eth_signTypedData_v4` payload with `"amount": -1` in a `uint256` field
    /// must produce a hash (the field is reported as an encoding error) rather than crash the app.
    @Test
    func negativeUIntInTypedDataDoesNotTrap() throws {
        let json = """
        {
          "types": {
            "EIP712Domain": [
              { "name": "name", "type": "string" },
              { "name": "chainId", "type": "uint256" }
            ],
            "Transfer": [
              { "name": "to", "type": "address" },
              { "name": "amount", "type": "uint256" }
            ]
          },
          "primaryType": "Transfer",
          "domain": { "name": "Test", "chainId": 1 },
          "message": { "to": "0x0000000000000000000000000000000000000001", "amount": -1 }
        }
        """

        let typedData = try JSONDecoder().decode(EIP712TypedData.self, from: Data(json.utf8))
        #expect(typedData.signHash.count == 32)
    }
}
