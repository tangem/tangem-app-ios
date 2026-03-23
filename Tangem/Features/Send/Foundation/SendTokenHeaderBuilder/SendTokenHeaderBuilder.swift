//
//  SendTokenHeaderBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemLocalization

struct SendTokenHeaderBuilder {
    let tokenHeader: TokenHeader
    let actionType: SendFlowActionType

    func makeSendTokenHeader(isSource: Bool = true) -> SendTokenHeader {
        switch (tokenHeader, actionType) {
        // For `.unstake` always show `stakingStakedAmount`
        case (_, .unstake):
            return .action(name: Localization.stakingStakedAmount)

        case (.account(let name, let icon), .swap) where isSource:
            return .account(prefix: Localization.commonFrom, name: name, icon: icon)

        case (.account(let name, let icon), .swap):
            return .account(prefix: Localization.commonTo, name: name, icon: icon)

        case (.account(let name, let icon), _):
            return .account(name: name, icon: icon)
        }
    }
}

// MARK: - TokenHeader+

extension TokenHeader {
    func asSendTokenHeader(actionType: SendFlowActionType, isSource: Bool = true) -> SendTokenHeader {
        SendTokenHeaderBuilder(tokenHeader: self, actionType: actionType).makeSendTokenHeader(isSource: isSource)
    }
}
