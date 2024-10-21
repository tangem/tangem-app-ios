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
}
