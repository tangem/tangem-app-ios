//
//  TangemPayOrderCardTypeRoutable.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol TangemPayOrderCardTypeRoutable: AnyObject {
    func orderCardTypeDidSelectVirtual()
    func orderCardTypeDidSelectPlastic()
    func closeOrderCardType()
}
