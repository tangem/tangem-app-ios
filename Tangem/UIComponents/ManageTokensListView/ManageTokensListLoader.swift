//
//  ManageTokensListLoader.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol ManageTokensListLoader: AnyObject {
    var hasNextPage: Bool { get }
    func fetch()
}
