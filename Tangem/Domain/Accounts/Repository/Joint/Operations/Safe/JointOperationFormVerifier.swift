//
//  JointOperationFormVerifier.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation

struct JointOperationFormVerifier {
    func verify(safeTransaction: SafeTransaction, safeAddress: String) throws {
        let innerCall: SafeInnerCall

        do {
            innerCall = try safeTransaction.innerCall
            _ = try SafeInnerCallTypeParser.parse(innerCall)
        } catch {
            throw JointOperationError.unsupportedOperationForm
        }

        guard !innerCall.to.caseInsensitiveEquals(to: safeAddress) else {
            throw JointOperationError.unsupportedOperationForm
        }
    }
}
