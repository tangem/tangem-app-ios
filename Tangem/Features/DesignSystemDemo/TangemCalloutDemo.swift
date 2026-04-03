//
//  TangemCalloutDemo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

final class TangemCalloutDemoViewModel: ObservableObject, Identifiable {}

struct TangemCalloutDemoView: View {
    @ObservedObject var viewModel: TangemCalloutDemoViewModel

    var body: some View {
        TangemCalloutShowcase()
            .navigationBarTitle(Text("TangemCallout"))
    }
}
