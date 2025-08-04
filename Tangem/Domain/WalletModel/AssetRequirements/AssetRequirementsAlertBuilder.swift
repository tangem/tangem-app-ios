//
//  AssetRequirementsAlertBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import enum BlockchainSdk.AssetRequirementsCondition
import TangemLocalization
import struct TangemUIUtils.AlertBinder
import enum BlockchainSdk.AssetRequirementFeeStatus

struct AssetRequirementsAlertBuilder {
    func fulfillAssetRequirementsAlert(
        for requirementsCondition: AssetRequirementsCondition?,
        feeTokenItem: TokenItem,
        feeStatus: AssetRequirementFeeStatus
    ) -> AlertBinder? {
        switch feeStatus {
        case .sufficient:
            return nil

        case .insufficient(let missingAmount):
            switch requirementsCondition {
            case .requiresTrustline:
                return AlertBinder(
                    title: "",
                    message: Localization.warningTokenRequiredMinCoinReserve(missingAmount, feeTokenItem.currencySymbol)
                )

            case .paidTransactionWithFee(blockchain: .hedera, _, feeAmount: .none):
                return AlertBinder(
                    title: "",
                    message: Localization.warningHederaTokenAssociationNotEnoughHbarMessage(feeTokenItem.currencySymbol)
                )

            case .paidTransactionWithFee(blockchain: .hedera, _, .some(let feeAmount)):
                assert(
                    feeAmount.type == feeTokenItem.amountType,
                    "Incorrect fee token item received: expected '\(feeAmount.currencySymbol)', got '\(feeTokenItem.currencySymbol)'"
                )
                return AlertBinder(
                    title: "",
                    message: Localization.warningHederaTokenAssociationNotEnoughHbarMessage(feeTokenItem.currencySymbol)
                )

            case .paidTransactionWithFee, .none:
                return nil
            }
        }
    }

    func fulfillmentAssetRequirementsFailedAlert(error: Error, networkName: String) -> AlertBinder {
        return .init(title: Localization.commonTransactionFailed, message: error.localizedDescription)
    }

    func fulfillAssetRequirementsDiscardedAlert(confirmationAction: @escaping () -> Void) -> AlertBinder {
        return AlertBinder(
            alert: Alert(
                title: Text(Localization.commonWarning),
                message: Text(Localization.warningKaspaUnfinishedTokenTransactionDiscardMessage),
                primaryButton: .default(Text(Localization.commonNo)),
                secondaryButton: .destructive(Text(Localization.commonYes), action: confirmationAction)
            )
        )
    }
}
