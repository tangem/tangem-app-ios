//
//  MainScreenPromoSheetModalBusySurface.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

enum MainScreenPromoSheetModalBusySurface {
    static func publisher(isModalPresented: Bool, modalPresences: [AnyPublisher<Bool, Never>]) -> AnyPublisher<Bool, Never> {
        Publishers.MergeMany(modalPresences.map { $0.removeDuplicates().dropFirst() })
            .map { _ in true }
            .prepend(isModalPresented)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}
