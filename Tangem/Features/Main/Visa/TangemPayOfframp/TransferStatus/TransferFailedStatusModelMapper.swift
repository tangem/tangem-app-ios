//
//  TransferFailedStatusModelMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemLocalization

enum TransferFailedStatusModelMapper {
    static func model(for error: TangemPayOffRampSendUseCase.SendError) -> TransferFailedStatusView.Model {
        switch error {
        case .unavailableRegion:
            TransferFailedStatusView.Model(
                title: Localization.tangempayWithdrawBankErrorRegionTitle,
                description: Localization.commonTryAgainLater,
                style: .unavailableRegion
            )

        case .signatureSubmission, .cancelled, .generic:
            TransferFailedStatusView.Model(
                title: Localization.tangempayWithdrawBankErrorGeneralTitle,
                description: nil,
                style: .generic
            )
        }
    }
}
