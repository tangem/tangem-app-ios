//
//  TangemMessageBannerDemo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

final class TangemMessageBannerDemoViewModel: ObservableObject, Identifiable {}

struct TangemMessageBannerDemoView: View {
    @ObservedObject var viewModel: TangemMessageBannerDemoViewModel

    var body: some View {
        TangemMessageBannerShowcase()
            .navigationBarTitle(Text("TangemMessageBanner"))
    }
}
