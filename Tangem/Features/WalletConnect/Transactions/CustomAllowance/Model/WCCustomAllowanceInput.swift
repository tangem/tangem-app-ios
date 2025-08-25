//
//  WCCustomAllowanceInput.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

struct WCCustomAllowanceInput {
    let approvalInfo: ApprovalInfo
    let tokenInfo: WCApprovalHelpers.TokenInfo
    let asset: BlockaidChainScanResult.Asset
    let updateAction: @MainActor (BigUInt) async -> Void
    let backAction: @MainActor () -> Void
}

extension WCCustomAllowanceInput: Equatable {
    static func == (lhs: WCCustomAllowanceInput, rhs: WCCustomAllowanceInput) -> Bool {
        lhs.approvalInfo == rhs.approvalInfo && lhs.tokenInfo == rhs.tokenInfo && lhs.asset == rhs.asset
    }
}
