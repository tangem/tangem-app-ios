//
//  ForEach+.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemFoundation

public extension ForEach {
    /// Useful for cases like `SwiftUI.ForEach` + non-zero-based integer-indexed collections.
    /// See https://onmyway133.com/posts/how-to-use-foreach-with-indices-in-swiftui/ for details.
    init<Base>(
        indexed data: Base,
        @ViewBuilder content: @escaping (Base.Index, Base.Element) -> Content
    ) where Content: View, Base: RandomAccessCollection, Base.Element: Identifiable, Data == [(Base.Index, Base.Element)], ID == Base.Element.ID {
        self.init(indexed: data, id: \.1.id, content: content)
    }

    init<Base>(
        indexed data: Base,
        id: KeyPath<(Base.Index, Base.Element), ID>,
        @ViewBuilder content: @escaping (Base.Index, Base.Element) -> Content
    ) where Content: View, Base: RandomAccessCollection, Data == [(Base.Index, Base.Element)] {
        self.init(Array(data.indexed()), id: id) { index, element in
            content(index, element)
        }
    }
}
