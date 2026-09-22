//
//  TransferFailedStatusModelMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum TransferFailedStatusModelMapper {
    static func model(for error: TangemPayOffRampSendUseCase.SendError) -> TransferFailedStatusView.Model {
        switch error {
        case .unavailableRegion:
            TransferFailedStatusView.Model(
                title: Constants.unavailableRegionTitle,
                description: Constants.unavailableRegionDescription,
                style: .unavailableRegion
            )

        case .signatureSubmission, .cancelled, .generic:
            TransferFailedStatusView.Model(
                title: Constants.genericTitle,
                description: nil,
                style: .generic
            )
        }
    }
}

// MARK: - Constants

private extension TransferFailedStatusModelMapper {
    enum Constants {
        static let genericTitle = "Something went wrong"
        static let unavailableRegionTitle = "Transfers are not available"
        static let unavailableRegionDescription = "Please try again later"
    }
}
