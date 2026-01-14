//
//  BaseAccountModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol BaseAccountModel: AccountModelAnalyticsProviding, Identifiable where ID: AccountModelPersistentIdentifierConvertible {
    typealias Editor = (_ editor: AccountModelEditor) -> Void

    var name: String { get }
    var icon: AccountModel.Icon { get }
    var didChangePublisher: AnyPublisher<Void, Never> { get }

    @discardableResult
    func edit(with editor: Editor) async throws(AccountEditError) -> Self
}
