//
//  ModalSheetPreferenceKey.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct ModalSheetPreferenceKey: PreferenceKey {
    static var defaultValue: Bool = false
    
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = nextValue()
    }
}

extension View {
    func updateModalPresentation(to newValue: Bool) -> some View {
        self.preference(key: ModalSheetPreferenceKey.self, value: newValue)
    }
}
