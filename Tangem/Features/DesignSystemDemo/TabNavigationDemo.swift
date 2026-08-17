//
//  TabNavigationDemo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

final class TabNavigationDemoViewModel: ObservableObject, Identifiable {}

struct TabNavigationDemoView: View {
    @ObservedObject var viewModel: TabNavigationDemoViewModel

    var body: some View {
        TabNavigationShowcase()
    }
}
