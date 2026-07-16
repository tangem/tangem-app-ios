//
//  SendFinishHeaderTitleProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemLocalization

protocol SendFinishHeaderTitleProvider {
    var title: String { get }
}

// MARK: - Send

struct TransferFinishHeaderTitleProvider: SendFinishHeaderTitleProvider {
    var title: String { Localization.sentTransactionSentTitle }
}

// MARK: - Sell

struct SellFinishHeaderTitleProvider: SendFinishHeaderTitleProvider {
    var title: String { Localization.sentTransactionSentTitle }
}

// MARK: - Send with Swap

struct SendWithSwapFinishHeaderTitleProvider: SendFinishHeaderTitleProvider {
    var title: String { Localization.sentTransactionSentTitle }
}

// MARK: - Swap

struct SwapFinishHeaderTitleProvider: SendFinishHeaderTitleProvider {
    weak var sourceTokenInput: SendSourceTokenInput?
    weak var receiveTokenInput: SendReceiveTokenInput?

    var title: String {
        switch (sourceTokenInput?.sourceToken, receiveTokenInput?.receiveToken) {
        case (.success(let source), .success(let receive)) where source.tokenItem.expressCurrency == receive.tokenItem.expressCurrency:
            return Localization.transferInProgressTitle
        default:
            return Localization.swapInProgress
        }
    }
}

// MARK: - Staking

struct StakingFinishHeaderTitleProvider: SendFinishHeaderTitleProvider {
    var title: String { Localization.sentTransactionSentTitle }
}

// MARK: - Onramp

struct OnrampFinishHeaderTitleProvider: SendFinishHeaderTitleProvider {
    var title: String { Localization.commonInProgress }
}
