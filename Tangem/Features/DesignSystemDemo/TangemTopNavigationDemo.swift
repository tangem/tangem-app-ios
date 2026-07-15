//
//  TangemTopNavigationDemo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

final class TangemTopNavigationDemoViewModel: ObservableObject, Identifiable {}

struct TangemTopNavigationDemoView: View {
    @ObservedObject var viewModel: TangemTopNavigationDemoViewModel

    var body: some View {
        TangemTopNavigationShowcase()
    }
}
