//
//  StepsFlowContent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct StepsFlowContent: View {
    @State private var title: String?
    @State private var leadingItem: StepsFlowNavBarItem?
    @State private var trailingItem: StepsFlowNavBarItem?
    @State private var isLoading: Bool = false

    let step: StepsFlowStep
    let onTitle: (String?) -> Void
    let onLeadingItem: (StepsFlowNavBarItem?) -> Void
    let onTrailingItem: (StepsFlowNavBarItem?) -> Void
    let onLoading: (Bool) -> Void

    var body: some View {
        AnyView(step.makeView())
            .toolbar(.hidden, for: .navigationBar)
            .onPreferenceChange(StepsFlowNavTitlePreferenceKey.self) { title in
                self.title = title
                onTitle(title)
            }
            .onPreferenceChange(StepsFlowNavLeadingItemPreferenceKey.self) { leadingItem in
                self.leadingItem = leadingItem
                onLeadingItem(leadingItem)
            }
            .onPreferenceChange(StepsFlowNavTrailingItemPreferenceKey.self) { trailingItem in
                self.trailingItem = trailingItem
                onTrailingItem(trailingItem)
            }
            .onPreferenceChange(StepsFlowNavTrailingItemPreferenceKey.self) { trailingItem in
                self.trailingItem = trailingItem
                onTrailingItem(trailingItem)
            }
            .onPreferenceChange(StepsFlowLoadingPreferenceKey.self) { isLoading in
                self.isLoading = isLoading
                onLoading(isLoading)
            }
            .onAppear {
                onTitle(title)
                onLeadingItem(leadingItem)
                onTrailingItem(trailingItem)
                onLoading(isLoading)
            }
    }
}
