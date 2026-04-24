//
//  MarketsTokenSearchStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol MarketsTokenSearchStorage: AnyObject, Sendable {
    var recentItemsPublisher: AnyPublisher<[MarketsTokenSearchRecentItem], Never> { get }

    func saveQuery(_ query: String) async
    func saveMarketAsset(_ tokenModel: MarketsTokenModel) async
    func clearAll() async
}
