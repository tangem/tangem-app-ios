//
//  ForEach+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

extension ForEach {
    init<Index, Element>(
        indexed indexedData: Data,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) where Content: View, Data: RandomAccessCollection, Data.Element == (Index, Element), Element: Identifiable, ID == Element.ID {
        self.init(indexedData, id: \.1.id, content: content)
    }
}
