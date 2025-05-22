//
//  FloatingSheetContentViewModel.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

public protocol FloatingSheetContentViewModel: ObservableObject, Identifiable {
    var id: String { get }

    var frameUpdateAnimation: Animation? { get }
    var frameUpdatePublisher: AnyPublisher<Void, Never> { get }
}

// MARK: - Defaults

public extension FloatingSheetContentViewModel {
    var frameUpdateAnimation: Animation? { nil }

    var frameUpdatePublisher: AnyPublisher<Void, Never> {
        objectWillChange
            .map { _ in () }
            .eraseToAnyPublisher()
    }
}
