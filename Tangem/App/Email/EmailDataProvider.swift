//
//  EmailDataProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol EmailDataProvider {
    var emailData: [EmailCollectedData] { get }
    var emailConfig: EmailConfig? { get }
}
