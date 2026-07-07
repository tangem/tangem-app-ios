//
//  TangemCheckboxV2.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

public struct TangemCheckboxV2: View, Setupable {
    private let value: Value
    private let action: () -> Void
    private var expandsHitArea = true

    public init(value: Value, action: @escaping () -> Void) {
        self.value = value
        self.action = action
    }

    public init(isOn: Binding<Bool>) {
        value = isOn.wrappedValue ? .checked : .unchecked
        action = { isOn.wrappedValue.toggle() }
    }

    public var body: some View {
        Button(action: action) {
            CheckboxMark(value: value)
        }
        .buttonStyle(Style(expandsHitArea: expandsHitArea))
        .accessibilityAddTraits(value == .checked ? .isSelected : [])
    }
}

// MARK: - Setupable setters

public extension TangemCheckboxV2 {
    func expandsHitArea(_ value: Bool = true) -> Self {
        map { $0.expandsHitArea = value }
    }
}

// MARK: - Public Type

public enum TangemCheckboxV2Value: Sendable, Hashable, CaseIterable {
    case unchecked
    case checked
    case indeterminate
}

public extension TangemCheckboxV2 {
    typealias Value = TangemCheckboxV2Value
}
