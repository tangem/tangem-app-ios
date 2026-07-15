//
//  TangemCheckmarkV2.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

public struct TangemCheckmarkV2: View, Setupable {
    private let checked: Bool
    private let action: () -> Void
    private var expandsHitArea = true

    public init(checked: Bool, action: @escaping () -> Void) {
        self.checked = checked
        self.action = action
    }

    public init(isOn: Binding<Bool>) {
        checked = isOn.wrappedValue
        action = { isOn.wrappedValue.toggle() }
    }

    public var body: some View {
        Button(action: action) {
            CheckmarkMark(checked: checked)
        }
        .buttonStyle(Style(expandsHitArea: expandsHitArea))
        .accessibilityAddTraits(checked ? .isSelected : [])
    }
}

// MARK: - Setupable setters

public extension TangemCheckmarkV2 {
    func expandsHitArea(_ value: Bool = true) -> Self {
        map { $0.expandsHitArea = value }
    }
}
