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
    let content: () -> Content

    init(@ViewBuilder _ content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        if #available(iOS 14.0, *) {
            ScrollView {
                LazyVStack {
                    content()
                }
            }
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
