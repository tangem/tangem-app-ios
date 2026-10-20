//
//  TangemPayWithdrawTypedDataFixture.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Foundation
import TangemPay

struct TangemPayWithdrawTypedDataFixture {
    static let collateral = "0xa52438e46D337cDe00b279D70Ae689db6ED68b55"

    var chainId: Int
    var quotesChainId = false
    var asset: String
    var recipient: String
    var amount: String
    var verifyingContract = Self.collateral
    var domainName = "Collateral"
    var domainVersion = "2"
    var primaryType = "Withdraw"
    var messageFields = ["address user", "address asset", "uint256 amount", "address recipient", "uint256 nonce"]
    var extraTypes: [String: [String]] = [:]
    var hash: Data?

    func makePreSignature() throws -> TangemPayWithdrawPreSignature {
        let declaredTypes = ["EIP712Domain": Self.domainFields, primaryType: messageFields]
        let types = extraTypes.merging(declaredTypes) { _, declared in declared }
        let typesJSON = types.map { "\"\($0.key)\": \(Self.json(fields: $0.value))" }.joined(separator: ", ")

        let json = """
        {
          "types": { \(typesJSON) },
          "primaryType": "\(primaryType)",
          "domain": {
            "name": "\(domainName)",
            "version": "\(domainVersion)",
            "chainId": \(quotesChainId ? "\"\(chainId)\"" : "\(chainId)"),
            "verifyingContract": "\(verifyingContract)",
            "salt": "\(Self.salt)"
          },
          "message": {
            "user": "\(Self.submitter)",
            "asset": "\(asset)",
            "amount": \(amount),
            "recipient": "\(recipient)",
            "nonce": 0
          }
        }
        """

        let typedData = try JSONDecoder().decode(EIP712TypedData.self, from: Data(json.utf8))

        return TangemPayWithdrawPreSignature(
            sender: Self.submitter,
            hash: hash ?? typedData.signHash,
            salt: Data(hexString: Self.salt),
            structuredData: typedData
        )
    }
}

private extension TangemPayWithdrawTypedDataFixture {
    static let submitter = "0xabe0b741c5ca100a05d62532cbebdc8891932305"
    static let salt = "0x7e6fbce06666687b5cdd26645510d435269556db9472c81ce51477e2329e870c"
    static let domainFields = ["string name", "string version", "uint256 chainId", "address verifyingContract", "bytes32 salt"]

    static func json(fields: [String]) -> String {
        let entries = fields.map { field in
            let parts = field.split(separator: " ")
            return "{ \"name\": \"\(parts[1])\", \"type\": \"\(parts[0])\" }"
        }

        return "[\(entries.joined(separator: ", "))]"
    }
}
