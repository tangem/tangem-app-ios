//
//  EmailDataProviderMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

class EmailDataProviderMock: EmailDataProvider {
    var emailData: [EmailCollectedData] { [] }
    var emailConfig: EmailConfig? { nil }
}
