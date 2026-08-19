//
//  UtilPriceChangeDemo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

final class UtilPriceChangeDemoViewModel: ObservableObject, Identifiable {}

struct UtilPriceChangeDemoView: View {
    @ObservedObject var viewModel: UtilPriceChangeDemoViewModel

    var body: some View {
        UtilPriceChangeShowcase()
            .navigationBarTitle(Text("UtilPriceChange"))
    }
}
