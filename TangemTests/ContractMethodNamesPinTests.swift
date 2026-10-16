//
//  ContractMethodNamesPinTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

/// The history decides what a transaction is by the name the shipped method list gives its id: the gasless fee
/// matcher looks for `gaslessTransaction`, the transfer classifier for the Yield-mode pair, the coin fee row for the
/// Yield-module call it names in its subtitle. Renaming any of them
/// in `contract_methods.json` silently changes what the history shows, so the names are pinned here.
@Suite("Contract method names the transaction history relies on")
struct ContractMethodNamesPinTests {
    @Test(
        "The shipped method list names the ids the history matches",
        arguments: [
            ("0x6234d42b", "gaslessTransaction"),
            ("0x4b072692", "gaslessTransaction"),
            ("0xf9b181bf", "gaslessTransaction"),
            ("0x0779afe6", "yieldSend"),
            ("0x79be55f7", "yieldEnter"),
            ("0xb4701e3e", "yieldClaim"),
            ("0xbebc896c", "yieldClaim"),
            ("0xb9de6a93", "yieldTopup"),
            ("0xc65e6dcf", "yieldWithdraw"),
            ("0xcbeda14c", "yieldDeploy"),
            ("0xebd4b81c", "yieldInit"),
            ("0xc478e956", "yieldReactivate"),
        ]
    )
    func methodIsNamed(id: String, name: String) {
        #expect(CommonSmartContractMethodMapper().getName(for: id) == name)
    }
}
