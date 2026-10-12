//
//  FilterGroupDemo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

final class FilterGroupDemoViewModel: ObservableObject, Identifiable {}

struct FilterGroupDemoView: View {
    @ObservedObject var viewModel: FilterGroupDemoViewModel

    var body: some View {
        FilterGroupShowcase()
            .navigationBarTitle(Text("FilterGroup"))
    }
}
