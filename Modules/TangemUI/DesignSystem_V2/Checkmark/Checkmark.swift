//
//  Checkmark.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUIUtils

public struct Checkmark: View, Setupable {
    private let value: Value
    private let action: () -> Void
    private var expandsHitArea = true
    private var size: Size = .size24

    public init(value: Value, action: @escaping () -> Void) {
        self.value = value
        self.action = action
    }

    public init(checked: Bool, action: @escaping () -> Void) {
        value = checked ? .checked : .unchecked
        self.action = action
    }

    public init(isOn: Binding<Bool>) {
        value = isOn.wrappedValue ? .checked : .unchecked
        action = { isOn.wrappedValue.toggle() }
    }

    public var body: some View {
        SwiftUI.Button(action: action) {
            CheckmarkMark(value: value, size: size)
        }
        .buttonStyle(Style(expandsHitArea: expandsHitArea))
        .accessibilityAddTraits(value == .checked ? .isSelected : [])
        .accessibilityValue(value == .error ? Localization.commonError : "")
    }
}

// MARK: - Setupable setters

public extension Checkmark {
    func expandsHitArea(_ value: Bool = true) -> Self {
        map { $0.expandsHitArea = value }
    }

    func size(_ size: Size) -> Self {
        map { $0.size = size }
    }
}

// MARK: - Public Type

public enum CheckmarkValue: Sendable, Hashable, CaseIterable {
    case unchecked
    case checked
    case error
}

public extension CheckmarkValue {
    var toggled: Self {
        switch self {
        case .checked: .unchecked
        case .unchecked, .error: .checked
        }
    }
}

public extension Checkmark {
    typealias Value = CheckmarkValue
    typealias Size = SelectionControlSize
}
