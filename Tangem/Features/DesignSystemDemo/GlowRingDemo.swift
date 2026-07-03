//
//  GlowRingDemo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

final class GlowRingDemoViewModel: ObservableObject, Identifiable {}

struct GlowRingDemoView: View {
    @ObservedObject var viewModel: GlowRingDemoViewModel

    var body: some View {
        GlowRingShowcase()
            .navigationBarTitle(Text("GlowRing"))
    }
}
