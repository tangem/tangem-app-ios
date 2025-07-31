//
//  XRPAddressValidationTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Testing
import BlockchainSdk

struct XRPAddressValidationTests {
    @Test(arguments: [
        "5553444300000000000000000000000000000000.rGm7WCVp9gb4jZHWTEtGUr4dd74z2XuWhE",
        "5553444300000000000000000000000000000000-rGm7WCVp9gb4jZHWTEtGUr4dd74z2XuWhE",
        "SLT.rfGCeDUdtbzKbXfgvrpG745qdC1hcZBz8S",
        "SLT-rfGCeDUdtbzKbXfgvrpG745qdC1hcZBz8S",
        "ATM.raDZ4t8WPXkmDfJWMLBcNZmmSHmBC523NZ",
        "ATM-raDZ4t8WPXkmDfJWMLBcNZmmSHmBC523NZ",
        "589.rfcasq9uRbvwcmLFvc4ti3j8Qt1CYCGgHz",
        "589-rfcasq9uRbvwcmLFvc4ti3j8Qt1CYCGgHz",
        "!?@.rfcasq9uRbvwcmLFvc4ti3j8Qt1CYCGgHz",
        "!?@-rfcasq9uRbvwcmLFvc4ti3j8Qt1CYCGgHz",
    ])
    func testValidCustomTokenAddresses(address: String) {
        let addressValidator: AddressValidator = AddressServiceFactory(blockchain: .xrp(curve: .secp256k1)).makeAddressService()
        #expect(addressValidator.validateCustomTokenAddress(address) == true, "Address should be valid: \(address)")
    }

    @Test(arguments: [
        // ❌ Missing .r part or malformed structure
        "SLT",
        "SLT.",
        ".rDTXLQ7ZKZVKz33zJbHjgVShjsBnqMBT2V",
        "TOO_LONG_PREFIX_TOKEN_EXCEEDS_LIMIT.rGm7WCVp9gb4jZHWTEtGUr4dd74z2XuWhE",

        // ❌ Invalid characters in prefix (only A-Za-z0-9 and specific symbols are allowed)
        "💩💩💩.rDTXLQ7ZKZVKz33zJbHjgVShjsBnqMBT2V",
        "abc💩.rDTXLQ7ZKZVKz33zJbHjgVShjsBnqMBT2V",

        // ❌ Issuer is too short
        "USD.r12",

        // ❌ Issuer is too long
        "USD.r123456789012345678901234567890123456789012345",

        // ❌ Not a valid base58 string (will fail XRPKit validation)
        "USD.rINVALIDADDRESS",
        "USD.r1111111111111111111111111111111111111111111",

        // ❌ Fails checksum (looks like base58 but invalid in XRPKit)
        "USD.rGfBamn39dXShmNKTn2ps5tNiCHoowr93Z" // last character modified
    ])
    func testInvalidCustomTokenAddresses(address: String) {
        let addressValidator: AddressValidator = AddressServiceFactory(blockchain: .xrp(curve: .secp256k1)).makeAddressService()
        #expect(addressValidator.validateCustomTokenAddress(address) == false, "Address should be invalid: \(address)")
    }
}
