//
//  View+DescriptionBottomSheet.swift
//  Tangem
//
//  Created by Andrew Son on 16/07/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

extension View {
    @ViewBuilder
    func descriptionBottomSheet(
        info: Binding<DescriptionBottomSheetInfo?>,
        backgroundColor: Color?
    ) -> some View {
        sheet(item: info) { info in
            DescriptionBottomSheetView(info: info)
                .adaptivePresentationDetents(isNavigationRequired: false)
                .background(backgroundColor.ignoresSafeArea(.all, edges: .bottom))
        }
    }
}
