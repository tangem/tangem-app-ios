//
//  Publisher+AppCurrencyCode.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

extension Publisher where Failure == Never {
    func withAppCurrencyCode() -> AnyPublisher<(Output, String), Never> {
        combineLatest(AppSettings.shared.$selectedCurrencyCode.removeDuplicates())
            .eraseToAnyPublisher()
    }
}
