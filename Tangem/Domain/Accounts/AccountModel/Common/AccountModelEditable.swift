//
//  AccountModelEditable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Sets a model's properties through an editor of its own kind, hence the associated type: the wallet's own accounts
/// take a name and an icon, a joint one takes its record on top of them.
/// - Note: `edit(with:)` goes through the delegate and the backend; `update(with:)` applies what the store already
/// holds directly and is for the account model registries alone.
/// - Warning: `Editor` has to be a concrete type. The inheriting protocols bound it (`Editor: AccountModelEditor`),
/// which is what lets both methods be called on `any CryptoAccountModel`, and an existential such as
/// `any AccountModelEditor` does not conform to its own protocol, so it cannot satisfy that bound.
protocol AccountModelEditable: AnyObject {
    associatedtype Editor

    @discardableResult
    func edit(with editor: (_ editor: Editor) -> Void) async throws(AccountEditError) -> Self

    @discardableResult
    func update(with editor: (_ editor: Editor) -> Void) -> Self
}
