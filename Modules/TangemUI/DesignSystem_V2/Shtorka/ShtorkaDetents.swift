//
//  ShtorkaDetents.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

public struct ShtorkaDetents: Equatable {
    public let collapsed: PresentationDetent
    public let medium: PresentationDetent
    public let full: PresentationDetent

    public var all: Set<PresentationDetent> { [collapsed, medium, full] }

    public init(
        collapsed: PresentationDetent = .height(ShtorkaMetrics.collapsedHeight),
        medium: PresentationDetent = .fraction(0.45),
        full: PresentationDetent = .large
    ) {
        self.collapsed = collapsed
        self.medium = medium
        self.full = full
    }

    public func detent(for size: ShtorkaSize) -> PresentationDetent {
        switch size {
        case .collapsed: collapsed
        case .medium: medium
        case .full: full
        }
    }

    /// Nothing but these detents reaches `presentationDetents`, so an unknown one means the sheet is being driven
    /// from somewhere else and the caller keeps the size it has.
    public func size(for detent: PresentationDetent) -> ShtorkaSize? {
        switch detent {
        case collapsed: return .collapsed
        case medium: return .medium
        case full: return .full
        default:
            assertionFailure("Unexpected `PresentationDetent` from sheet")
            return nil
        }
    }
}
