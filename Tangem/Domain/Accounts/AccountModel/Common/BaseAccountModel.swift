//
//  BaseAccountModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol BaseAccountModel {
    var name: String { get }
    var icon: AccountModel.Icon { get }
    var didChangePublisher: any Publisher<Void, Never> { get }

    func setName(_ name: String) async throws
    func setIcon(_ icon: AccountModel.Icon) async throws
}
