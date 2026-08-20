//
//  TangemPayOrderCardDataRoutable.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol TangemPayOrderCardDataRoutable: AnyObject {
    func orderCardDataDidPlaceOrder()
    func orderCardDataDidGoBack()
    func closeOrderCardData()
}
