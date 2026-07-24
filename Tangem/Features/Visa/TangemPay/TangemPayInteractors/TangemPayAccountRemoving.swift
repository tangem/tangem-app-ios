//
//  TangemPayAccountRemoving.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol TangemPayAccountRemoving: AnyObject {
    func removeAccount(onFinish: @escaping (Bool) -> Void)
}
