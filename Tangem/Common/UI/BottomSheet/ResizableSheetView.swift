//
//  ResizableSheetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

enum ResizeSheetAction {
    case increment(value: CGFloat)
    case decrement(value: CGFloat)
    case setNewValue(value: CGFloat)
}

protocol ResizableSheetView: View {
    var updateHeight: ((ResizeSheetAction) -> ())? { get set }
}

struct BottomSheetEmptyView: ResizableSheetView {
    var updateHeight: ((ResizeSheetAction) -> ())?

    var body: some View {
        EmptyView()
    }
}
