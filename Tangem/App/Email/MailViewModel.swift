//
//  MailViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct MailViewModel: Identifiable {
    let id: UUID = .init()

    let logsComposer: LogsComposer
    let recipient: String
    let emailType: EmailType
}
