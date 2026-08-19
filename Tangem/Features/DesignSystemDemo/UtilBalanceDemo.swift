//
//  UtilBalanceDemo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

final class UtilBalanceDemoViewModel: ObservableObject, Identifiable {}

struct UtilBalanceDemoView: View {
    @ObservedObject var viewModel: UtilBalanceDemoViewModel

    var body: some View {
        UtilBalanceShowcase()
            .navigationBarTitle(Text("UtilBalance"))
    }
}
