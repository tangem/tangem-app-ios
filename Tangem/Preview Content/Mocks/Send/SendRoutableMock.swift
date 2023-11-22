//
//  SendRoutableMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

class SendRoutableMock: SendRoutable {
    init() {}

    func dismiss() {}
    func openMail(with dataCollector: EmailDataCollector, recipient: String) {}
}
