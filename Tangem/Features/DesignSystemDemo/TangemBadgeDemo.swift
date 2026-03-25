//
//  TangemBadgeDemo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

final class TangemBadgeDemoViewModel: ObservableObject, Identifiable {}

struct TangemBadgeDemoView: View {
    @ObservedObject var viewModel: TangemBadgeDemoViewModel

    var body: some View {
        TangemBadgeShowcase()
            .navigationBarTitle(Text("TangemBadge"))
    }
}
