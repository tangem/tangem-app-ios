//
//  View+InfinityFrame.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

extension View {
    func infinityFrame(
        axis: Axis.Set = .both,
        alignment: Alignment = .center
    ) -> some View {
        modifier(InfinityFrameViewModifier(axis: axis, alignment: alignment))
    }
}

extension Axis.Set {
    static var both: Self { [.horizontal, .vertical] }
}

// MARK: - Private implementation

private struct InfinityFrameViewModifier: ViewModifier {
    let axis: Axis.Set
    let alignment: Alignment

    func body(content: Content) -> some View {
        content
            .frame(
                minWidth: axis.contains(.horizontal) ? 0.0 : nil,
                maxWidth: axis.contains(.horizontal) ? .infinity : nil,
                minHeight: axis.contains(.vertical) ? 0.0 : nil,
                maxHeight: axis.contains(.vertical) ? .infinity : nil,
                alignment: alignment
            )
    }
}
