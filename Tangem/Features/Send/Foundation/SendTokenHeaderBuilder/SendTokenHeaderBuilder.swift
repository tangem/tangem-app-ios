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

        case (.wallet(_, hasOnlyOneWallet: true), .send):
            return .action(name: Localization.sendFromTitle)

        case (.wallet(_, hasOnlyOneWallet: true), .swap) where isSource,
             (.wallet(_, hasOnlyOneWallet: true), .sendViaSwap) where isSource:
            return .action(name: Localization.swappingFromTitleV2)

        case (.wallet(_, hasOnlyOneWallet: true), .swap),
             (.wallet(_, hasOnlyOneWallet: true), .sendViaSwap):
            return .action(name: Localization.swappingToTitle)

        case (.wallet(let name, hasOnlyOneWallet: false), .swap) where isSource,
             (.wallet(let name, hasOnlyOneWallet: false), .sendViaSwap) where isSource:
            return .wallet(name: Localization.commonFromWalletName(name))

        case (.wallet(let name, hasOnlyOneWallet: false), .swap),
             (.wallet(let name, hasOnlyOneWallet: false), .sendViaSwap):
            return .wallet(name: Localization.commonToWalletName(name))

        case (.account(let name, let icon), .swap) where isSource,
             (.account(let name, let icon), .sendViaSwap) where isSource:
            return .account(prefix: Localization.swappingFromAccountTitle, name: name, icon: icon)

        case (.account(let name, let icon), .swap),
             (.account(let name, let icon), .sendViaSwap):
            return .account(prefix: Localization.swappingToAccountTitle, name: name, icon: icon)

        case (.wallet(let name, _), _):
            return .wallet(name: Localization.commonFromWalletName(name))

        case (.account(let name, let icon), _):
            return .account(name: name, icon: icon)
        }
    }

    func makeLegacySendTokenHeader(isSource: Bool = true) -> SendTokenHeader {
        switch (tokenHeader, actionType) {
        // For `.unstake` always show `stakingStakedAmount`
        case (_, .unstake):
            return .action(name: Localization.stakingStakedAmount)

        case (.wallet(_, hasOnlyOneWallet: true), .send):
            return .action(name: Localization.sendFromTitle)

        case (.wallet(_, hasOnlyOneWallet: true), .swap) where isSource:
            return .action(name: Localization.swappingFromTitle)

        case (.wallet(_, hasOnlyOneWallet: true), .swap):
            return .action(name: Localization.swappingToTitle)

        case (.wallet(let name, hasOnlyOneWallet: false), .swap) where isSource:
            return .wallet(name: Localization.commonFromWalletName(name))

        case (.wallet(let name, hasOnlyOneWallet: false), .swap):
            return .wallet(name: Localization.commonToWalletName(name))

        case (.account(let name, let icon), .swap) where isSource:
            return .account(prefix: Localization.commonFrom, name: name, icon: icon)

        case (.account(let name, let icon), .swap):
            return .account(prefix: Localization.commonTo, name: name, icon: icon)

        case (.wallet(let name, _), _):
            return .wallet(name: Localization.commonFromWalletName(name))

        case (.account(let name, let icon), _):
            return .account(name: name, icon: icon)
        }
    }
}

// MARK: - TokenHeader+

extension TokenHeader {
    func asSendTokenHeader(actionType: SendFlowActionType, isSource: Bool = true) -> SendTokenHeader {
        if FeatureProvider.isAvailable(.swapInProgressV2) {
            return SendTokenHeaderBuilder(tokenHeader: self, actionType: actionType).makeSendTokenHeader(isSource: isSource)
        }

        // Legacy method doesn't know `.sendViaSwap`; treat it as `.send` to preserve pre-toggle behavior.
        let legacyActionType: SendFlowActionType = actionType == .sendViaSwap ? .send : actionType
        return SendTokenHeaderBuilder(tokenHeader: self, actionType: legacyActionType).makeLegacySendTokenHeader(isSource: isSource)
    }
}
