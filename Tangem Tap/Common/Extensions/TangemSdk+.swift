//
//  TangemSdk+.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

extension TangemSdk {
    var signer: TransactionSigner {
        let signer = DefaultSigner(tangemSdk: self,
                                   initialMessage: Message(header: nil,
                                                           body: "initial_message_sign_header".localized))
        return signer
    }
}
