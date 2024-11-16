//
//  ActionButtonsSellRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol ActionButtonsSellRoutable: AnyObject {
    func openSellCrypto(
        at url: URL,
        makeSellToSendToModel: @escaping (String) -> ActionButtonsSendToSellModel?
    )
    func dismiss()
}
