//
//  SendSummaryRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol SendSummaryRoutable: AnyObject {
    func openStep(_ step: SendStep)
}
