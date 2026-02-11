//
//  MarketsWidgetEarnProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

protocol MarketsWidgetEarnProvider {
    var earnResultPublisher: AnyPublisher<LoadingResult<[EarnTokenModel], Error>, Never> { get }
    var earnResult: LoadingResult<[EarnTokenModel], Error> { get }

    func fetch()
}
