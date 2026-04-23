//
//  TokenSearchStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol TokenSearchStorage: AnyObject, Sendable {
    var recentItemsPublisher: AnyPublisher<[TokenSearchRecentItem], Never> { get }

    func saveQuery(_ query: String) async
    func saveMarketAsset(_ tokenModel: MarketsTokenModel) async
    func clearAll() async
}
