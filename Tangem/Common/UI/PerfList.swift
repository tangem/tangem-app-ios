//
//  PerfList.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct PerfList<Content: View>: View {
    let dismissKeyboardOnScroll: Bool
    let content: () -> Content

    init(dismissKeyboardOnScroll: Bool = true, @ViewBuilder _ content: @escaping () -> Content) {
        self.dismissKeyboardOnScroll = dismissKeyboardOnScroll
        self.content = content
    }

    var body: some View {
        ScrollView {
            LazyVStack {
                content()
            }
        }
        .scrollDismissesKeyboardCompat(dismissKeyboardOnScroll)
    }
}

struct PerfListDivider: View {
    var body: some View {
        Divider()
            .padding([.leading])
    }
}

extension View {
    @ViewBuilder
    func perfListPadding() -> some View {
        padding(.horizontal)
    }
}
