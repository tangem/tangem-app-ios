//
//  FloatingSheetView+ContentFrameUpdate.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

public extension View {
    func floatingSheetContentFrameUpdatePublisher<Value>(_ publisher: Published<Value>.Publisher) -> some View {
        preference(
            key: FloatingSheetFrameUpdateTriggerPreferenceKey.self,
            value: .init(
                id: 1,
                publisher: publisher
                    .map { _ in
                        return ()
                    }
                    .eraseToAnyPublisher()
            )
        )
    }
}

public struct FloatingSheetFrameUpdateAnimationPreferenceKey: PreferenceKey {
    public static let defaultValue: Animation? = nil

    public static func reduce(value: inout Animation?, nextValue: () -> Animation?) {
        value = nextValue()
    }
}

public struct EquatablePublisherProxy: Equatable {
    let id: Int
    let publisher: AnyPublisher<Void, Never>

    static let initialDummyValue = EquatablePublisherProxy(id: -1, publisher: Just(()).eraseToAnyPublisher())

    init(id: Int, publisher: AnyPublisher<Void, Never>) {
        self.id = id
        self.publisher = publisher
    }

    public static func == (lhs: EquatablePublisherProxy, rhs: EquatablePublisherProxy) -> Bool {
        lhs.id == rhs.id
    }
}

public struct FloatingSheetFrameUpdateTriggerPreferenceKey: PreferenceKey {
    public static let defaultValue = EquatablePublisherProxy.initialDummyValue

    // [REDACTED_USERNAME], this empty implementation will keep the very first publisher, and ignore the rest.
    public static func reduce(value: inout EquatablePublisherProxy, nextValue: () -> EquatablePublisherProxy) {}
}
