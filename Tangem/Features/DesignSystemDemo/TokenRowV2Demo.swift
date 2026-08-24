//
//  TokenRowV2Demo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

final class TokenRowV2DemoViewModel: ObservableObject, Identifiable {}

struct TokenRowV2DemoView: View {
    @ObservedObject var viewModel: TokenRowV2DemoViewModel

    var body: some View {
        TokenRowShowcase()
            .navigationBarTitle(Text("TokenRow"))
    }
}
