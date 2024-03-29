//
//  MailViewModel.swift
//  Tangem
//
//  Created by Alexander Osokin on 15.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct MailViewModel: Identifiable {
    let id: UUID = .init()

    let logsComposer: LogsComposer
    let recipient: String
    let emailType: EmailType
}
