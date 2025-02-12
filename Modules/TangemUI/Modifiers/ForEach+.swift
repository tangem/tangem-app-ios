//
//  ForEach+.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

public extension ForEach {
    /// Useful for cases like `SwiftUI.ForEach` + non-zero-based integer-indexed collections.
    /// See https://onmyway133.com/posts/how-to-use-foreach-with-indices-in-swiftui/ for details.
    init<Index, Element>(
        indexed indexedData: Data,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) where Content: View, Data: RandomAccessCollection, Data.Element == (Index, Element), Element: Identifiable, ID == Element.ID {
        self.init(indexedData, id: \.1.id, content: content)
    }
}
