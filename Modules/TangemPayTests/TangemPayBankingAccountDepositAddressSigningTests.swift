//
//  TangemPayBankingAccountDepositAddressSigningTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import CryptoSwift
import Foundation
import TangemSdk
import Testing
@testable import TangemPay

@Suite("Banking account deposit address signing message")
struct TangemPayBankingAccountDepositAddressSigningTests {
    @Test("The message names the deposit address in lower case whatever case it came in")
    func messageLowercasesAddress() throws {
        let signRequest = try TangemPayUtilities.prepareBankingAccountDepositAddressForSign(
            depositAddress: "0xAbCdEf0123456789abcdef0123456789ABCDEF01"
        )

        #expect(signRequest.message == "Banking account deposit address 0xabcdef0123456789abcdef0123456789abcdef01")
    }

    @Test("The hash is the EIP-191 personal-message keccak of the message")
    func hashIsEIP191PersonalMessageKeccak() throws {
        let address = "0xabcdef0123456789abcdef0123456789abcdef01"
        let message = "Banking account deposit address \(address)"
        let expected = Data("\u{19}Ethereum Signed Message:\n\(message.count)\(message)".utf8).sha3(.keccak256)

        let signRequest = try TangemPayUtilities.prepareBankingAccountDepositAddressForSign(depositAddress: address)

        #expect(signRequest.hash == expected)
        #expect(signRequest.hash.count == 32)
    }

    @Test("The banking account key sits one index below the customer wallet key")
    func bankingAccountDerivationPathIsReserved() {
        #expect(TangemPayUtilities.bankingAccountDerivationPath.rawPath == "m/44'/60'/999998'/0/0")
        #expect(TangemPayUtilities.bankingAccountDerivationPath != TangemPayUtilities.derivationPath)
    }
}
