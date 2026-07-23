//
//  TangemMessageBubbleDemo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

final class TangemMessageBubbleDemoViewModel: ObservableObject, Identifiable {}

struct TangemMessageBubbleDemoView: View {
    @ObservedObject var viewModel: TangemMessageBubbleDemoViewModel

    var body: some View {
        TangemMessageBubbleShowcase()
            .navigationBarTitle(Text("TangemMessageBubble"))
    }
}
