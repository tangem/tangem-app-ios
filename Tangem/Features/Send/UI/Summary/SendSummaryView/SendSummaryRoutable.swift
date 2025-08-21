//
//  SendSummaryStepsRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol SendSummaryStepsRoutable: AnyObject {
    func summaryStepRequestEditDestination()
    func summaryStepRequestEditAmount()
    func summaryStepRequestEditFee()
    func summaryStepRequestEditValidators()
    func summaryStepRequestEditProviders()
}

extension SendSummaryStepsRoutable {
    func summaryStepRequestEditDestination() {
        assertionFailure("This action is not implemented")
    }

    func summaryStepRequestEditAmount() {
        assertionFailure("This action is not implemented")
    }

    func summaryStepRequestEditFee() {
        assertionFailure("This action is not implemented")
    }

    func summaryStepRequestEditValidators() {
        assertionFailure("This action is not implemented")
    }

    func summaryStepRequestEditProviders() {
        assertionFailure("This action is not implemented")
    }
}
