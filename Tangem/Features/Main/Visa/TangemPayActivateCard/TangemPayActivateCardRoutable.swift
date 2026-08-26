//
//  TangemPayActivateCardRoutable.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol TangemPayActivateCardRoutable: AnyObject {
    func activateCardDidFinish(cardId: String)
    func closeActivateCard()
}
