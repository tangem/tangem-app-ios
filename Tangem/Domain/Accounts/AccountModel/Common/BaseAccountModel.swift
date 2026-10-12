//
//  BaseAccountModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol BaseAccountModel: AnyObject, AccountModelAnalyticsProviding, AccountModelResolvable, Identifiable where ID: AccountModelPersistentIdentifierConvertible {
    associatedtype Icon: AccountModelIconConvertible

    var name: String { get }
    var icon: Icon { get }
    var didChangePublisher: AnyPublisher<Void, Never> { get }
}
