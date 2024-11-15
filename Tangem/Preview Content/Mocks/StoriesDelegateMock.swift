//
//  StoriesDelegateMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class StoriesDelegateMock: StoriesDelegate {
    var isScanning: AnyPublisher<Bool, Never> { Just(false).eraseToAnyPublisher() }

    func scanCard() {}

    func orderCard() {}

    func openPromotion() {}

    func openTokenList() {}
}
