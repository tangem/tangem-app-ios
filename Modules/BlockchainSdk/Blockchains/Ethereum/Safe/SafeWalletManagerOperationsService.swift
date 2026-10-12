//
//  SafeWalletManagerOperationsService.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// What a wallet manager whose wallet lives at a Safe does towards an operation: reads the Safe, shapes the inner call
/// and prices it. Signing the operation, who is allowed to and where the signature goes is the caller's business.
public protocol SafeWalletManagerOperationsService: AnyObject {
    /// The Safe at the wallet's address in this network: not deployed yet, or its nonce, owners and threshold.
    func getSafeState() async throws -> SafeContractState

    /// A transfer of the coin as a bare call at the recipient, of a token as a `transfer` call on its contract. Other
    /// kinds of inner call take their place beside it as the operations that need them arrive.
    func makeSafeInnerTransferCall(amount: Amount, destination: String) throws -> SafeInnerCall

    /// Prices the inner call the way the Safe refunds its relayer: the call's gas with the buffer, the network's price
    /// with the margin, and the base gas with the deployment folded in while the Safe is not deployed yet. The terms
    /// travel inside the fee as `SafeTransactionFeeParameters`.
    func getSafeOperationFee(innerCall: SafeInnerCall, parameters: SafeOperationParameters) async throws -> Fee
}
