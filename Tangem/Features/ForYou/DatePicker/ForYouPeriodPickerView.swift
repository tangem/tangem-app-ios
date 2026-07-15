//
//  ForYouPeriodPickerView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct ForYouPeriodPickerView: View {
    let segments: [ForYouPeriodSegment]

    @Binding var selection: ForYouPeriodSegment

    var body: some View {
        TangemSegmentedPicker(data: segments, selection: $selection)
            .style(.flexible)
    }
}

#Preview {
    ForYouPeriodPickerView(
        segments: ForYouPeriodSegment.all,
        selection: .constant(ForYouPeriodSegment.initial)
    )
}
