//
//  BaseAccountModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

// [REDACTED_TODO_COMMENT]
protocol BaseAccountModel: Identifiable where ID: AccountModelPersistentIdentifierConvertible {
    var name: String { get }
    var icon: AccountModel.Icon { get }

    func setName(_ name: String)
    func setIcon(_ icon: AccountModel.Icon)
    var didChangePublisher: AnyPublisher<Void, Never> { get }
}
