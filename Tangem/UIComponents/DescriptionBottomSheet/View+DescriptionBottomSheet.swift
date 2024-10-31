//
//  View+DescriptionBottomSheet.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

extension View {
    @ViewBuilder
    func tokenDescriptionBottomSheet(
        info: Binding<DescriptionBottomSheetInfo?>,
        backgroundColor: Color?,
        onGeneratedAITapAction: (() -> Void)?
    ) -> some View {
        sheet(item: info) { info in
            TokenDescriptionBottomSheetView(info: info, generatedWithAIAction: onGeneratedAITapAction)
                .adaptivePresentationDetents()
                .background(
                    backgroundColor
                        .ignoresSafeArea(edges: .bottom)
                )
        }
    }
}
