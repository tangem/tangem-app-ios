//
//  MainQRSendParametersFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk

struct MainQRSendParametersFactory {
    func makeSendParameters(
        destination: String,
        amount: Decimal?,
        tag: String?
    ) -> PredefinedSendParameters {
        let initialStep: PredefinedSendParameters.InitialStep = amount == nil ? .amountThenSummary : .summary
        return PredefinedSendParameters(
            destination: destination,
            amount: amount,
            tag: tag,
            initialStep: initialStep
        )
    }

    func resolveSendParameters(
        _ parameters: PredefinedSendParameters,
        sourceToken: SendWithSwapToken
    ) -> PredefinedSendParameters {
        guard parameters.initialStep == .summary else {
            return parameters
        }

        guard shouldStartFromSummary(parameters: parameters, sourceToken: sourceToken) else {
            return PredefinedSendParameters(
                destination: parameters.destination,
                amount: parameters.amount,
                tag: parameters.tag,
                initialStep: .amountThenSummary
            )
        }

        return parameters
    }

    private func shouldStartFromSummary(
        parameters: PredefinedSendParameters,
        sourceToken: SendWithSwapToken
    ) -> Bool {
        guard let amount = parameters.amount, amount > 0 else {
            return false
        }

        let amountToSend = Amount(
            with: sourceToken.tokenItem.blockchain,
            type: sourceToken.tokenItem.amountType,
            value: amount
        )

        do {
            try sourceToken.transactionValidator.validate(amount: amountToSend)
        } catch {
            return false
        }

        if let selectedFee = sourceToken.tokenFeeProvidersManager.selectedTokenFee.value.value {
            do {
                try sourceToken.transactionValidator.validate(amount: amountToSend, fee: selectedFee)
                return true
            } catch {
                return false
            }
        }

        return true
    }
}
