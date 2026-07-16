//
//  TangemShimmerDemo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

final class TangemShimmerDemoViewModel: ObservableObject, Identifiable {}

struct TangemShimmerDemoView: View {
    @ObservedObject var viewModel: TangemShimmerDemoViewModel

    var body: some View {
        TangemShimmerShowcase()
            .navigationBarTitle(Text("TangemShimmer"))
    }
}
