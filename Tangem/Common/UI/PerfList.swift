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
        if #available(iOS 14.0, *) {
            ScrollView {
                LazyVStack {
                    content()
                }
            }
            .scrollDismissesKeyboardCompat(dismissKeyboardOnScroll)
        } else {
            List {
                content()
            }
            .listStyle(PlainListStyle())
        }
    }
}

struct PerfListDivider: View {
    var body: some View {
        if #available(iOS 14.0, *) {
            Divider()
                .padding([.leading])
        } else {
            EmptyView()
        }
    }
}

extension View {
    @ViewBuilder func perfListPadding() -> some View {
        if #available(iOS 14.0, *) {
            self.padding(.horizontal)
        } else {
            self
        }
    }
}
