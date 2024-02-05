//
//  View+LegacyBottomSheet.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

extension View {
    @available(*, deprecated, message: "Use bottomSheet method with BottomSheetModifier")
    func bottomSheet<Content: View>(
        isPresented: Binding<Bool>,
        viewModelSettings: BottomSheetSettings,
        @ViewBuilder contentView: @escaping () -> Content
    ) -> some View {
        modifier(LegacyBottomSheetModifier(isPresented: isPresented, viewModelSettings: viewModelSettings, contentView: contentView))
    }
}
