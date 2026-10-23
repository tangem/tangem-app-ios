//
//  MainScreenPromoSheetHost.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

protocol MainScreenPromoSheetHost: AnyObject {
    var busySurfacePublishers: [AnyPublisher<Bool, Never>] { get }
}
