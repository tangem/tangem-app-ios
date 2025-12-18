//
//  AddActionButton.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

public struct AddListItemButton: View {
    private let viewData: ViewData

    public init(viewData: ViewData) {
        self.viewData = viewData
    }

    public var body: some View {
        Button(action: viewData.buttonAction) {
            HStack(spacing: 12) {
                plusIcon

                Text(viewData.text)
                    .style(Fonts.Bold.subheadline, color: textAndIconColor)

                Spacer()
            }
        }
        .disabled(!viewData.isEnabled)
        .onTapGesture(perform: viewData.disabledActionIfNeeded)
    }

    private var plusIcon: some View {
        PlusIconView(textAndIconColor: textAndIconColor, isEnabled: viewData.isEnabled)
    }

    private var textAndIconColor: Color {
        if viewData.isEnabled {
            return Colors.Text.accent
        }

        return Colors.Text.disabled
    }
}

public extension AddListItemButton {
    struct ViewData: Identifiable {
        public var id: String {
            text
        }

        let text: String
        let state: State

        public init(text: String, state: State) {
            self.text = text
            self.state = state
        }

        public static let initial = Self(text: "", state: .enabled(action: {}))

        var buttonAction: () -> Void {
            switch state {
            case .enabled(let action):
                return action
            case .disabled:
                return {}
            }
        }

        func disabledActionIfNeeded() {
            switch state {
            case .enabled:
                break
            case .disabled(let action):
                action?()
            }
        }

        var isEnabled: Bool {
            switch state {
            case .enabled:
                return true
            case .disabled:
                return false
            }
        }
    }
}

public extension AddListItemButton {
    enum State {
        case enabled(action: () -> Void)
        case disabled(action: (() -> Void)? = nil)
    }
}

#if DEBUG
#Preview {
    VStack {
        AddListItemButton(viewData: AddListItemButton.ViewData(text: "Add account", state: .enabled(action: {})))
        AddListItemButton(viewData: AddListItemButton.ViewData(text: "Add account (disabled, no action)", state: .disabled()))
        AddListItemButton(viewData: AddListItemButton.ViewData(text: "Add account (disabled, with action)", state: .disabled(action: { print("Tapped disabled button") })))
    }
}
#endif
