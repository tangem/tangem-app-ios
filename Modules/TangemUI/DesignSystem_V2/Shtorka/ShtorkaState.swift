//
//  ShtorkaState.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

public extension EnvironmentValues {
    /// The state of the enclosing shtorka, so content at any depth can reach it without plumbing.
    /// The environment only hands the object down: a view that shows `size` observes `sizePublisher`
    /// (`onReceive`), a plain `@Environment` read does not refresh on mutation.
    @Entry var shtorka: ShtorkaState?
}

public final class ShtorkaState {
    /// The detent the shtorka rests at or is heading to. Assign it to move the shtorka.
    public var size: ShtorkaSize {
        get { sizeSubject.value }
        set { sizeSubject.send(newValue) }
    }

    public var sizePublisher: AnyPublisher<ShtorkaSize, Never> {
        sizeSubject.removeDuplicates().eraseToAnyPublisher()
    }

    /// Changes on every frame of a drag: debounce it, never render from it.
    public var expansionProgressPublisher: AnyPublisher<CGFloat, Never> {
        expansionProgressSubject.removeDuplicates().eraseToAnyPublisher()
    }

    private let sizeSubject = CurrentValueSubject<ShtorkaSize, Never>(.collapsed)
    private let expansionProgressSubject = CurrentValueSubject<CGFloat, Never>(0)

    public init() {}

    func report(expansionProgress: CGFloat) {
        expansionProgressSubject.send(expansionProgress)
    }
}
