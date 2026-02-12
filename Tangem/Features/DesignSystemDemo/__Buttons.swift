//
//  __Buttons.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

final class ButtonComponentDemoCoordinator: CoordinatorObject {
    let dismissAction: Action<DismissOptions?>
    let popToRootAction: Action<PopToRootOptions>

    @Published private(set) var rootViewModel: ButtonComponentDemoViewModel?

    required init(
        dismissAction: @escaping Action<DismissOptions?>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Void) {
        rootViewModel = .init()
    }
}

extension ButtonComponentDemoCoordinator {
    struct Options {}
    typealias DismissOptions = Void
}

struct ButtonComponentDemoCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: ButtonComponentDemoCoordinator

    var body: some View {
        ZStack {
            if let rootViewModel = coordinator.rootViewModel {
                ButtonComponentDemoView(viewModel: rootViewModel)
            }
        }
    }
}

final class ButtonComponentDemoViewModel: ObservableObject {}

typealias _Button = TangemUI.TangemButton

struct ButtonComponentDemoView: View {
    @ObservedObject var viewModel: ButtonComponentDemoViewModel

    @State private var cornerStyle: _Button.CornerStyle = .default
    @State private var styleType: _Button.StyleType = .accent
    @State private var buttonState: _Button.ButtonState = .normal
    @State private var content: _Button.Content = .text("Button")
    @State private var horLayout: _Button.HorizontalLayout = .intrinsic
    @State private var size: _Button.Size = .x12

    let cornerStyles: [_Button.CornerStyle] = [
        .default,
        .rounded,
    ]

    let styleTypes: [_Button.StyleType] = [
        .accent,
        .primary,
        .secondary,
        .outline,
        .ghost,
        .primaryInverse,
        .positive,
    ]

    let buttonStates: [_Button.ButtonState] = [
        .normal,
        .disabled,
        .loading,
    ]

    let horizontalLayouts: [_Button.HorizontalLayout] = [
        .intrinsic,
        .infinity,
    ]

    let sizes: [_Button.Size] = [
        .x15,
        .x12,
        .x10,
        .x9,
        .x8,
        .x7,
    ]

    let contents: [_Button.Content] = [
        .text("Button"),
        .icon(demoIcon),
        .combined(text: "Button", icon: demoIcon, iconPosition: .left),
        .combined(text: "Button", icon: demoIcon, iconPosition: .right),
        .text("Button alskjdhlkaujshdlagsdhaiusjcklsxcbvhjksfdskagfgasjkhdfajksdfhjkasfasdfkasdfl;a"),
    ]

    var body: some View {
        VStack(spacing: 8) {
            PickerView(contents: [
                "default",
                "rounded",
            ], selection: .init(get: {
                cornerStyles.firstIndex(of: cornerStyle)!
            }, set: { index in
                cornerStyle = cornerStyles[index]
            }))

            PickerView(contents: [
                "accent",
                "primary",
                "secondary",
                "outline",
                "ghost",
                "primaryInverse",
                "positive",
            ], selection: .init(get: {
                styleTypes.firstIndex(of: styleType)!
            }, set: { index in
                styleType = styleTypes[index]
            }))

            PickerView(contents: [
                "normal",
                "disabled",
                "loading",
            ], selection: .init(get: {
                buttonStates.firstIndex(of: buttonState)!
            }, set: { index in
                buttonState = buttonStates[index]
            }))

            PickerView(contents: [
                "intrinsic",
                "infinity",
            ], selection: .init(get: {
                horizontalLayouts.firstIndex(of: horLayout)!
            }, set: { index in
                horLayout = horizontalLayouts[index]
            }))

            PickerView(contents: [
                "x15",
                "x12",
                "x10",
                "x9",
                "x8",
                "x7",
            ], selection: .init(get: {
                sizes.firstIndex(of: size)!
            }, set: { index in
                size = sizes[index]
            }))

            PickerView(contents: [
                "text",
                "icon",
                "combinedLeft",
                "combinedRight",
                "gigaText",
            ], selection: .init(get: {
                contents.firstIndex(of: content)!
            }, set: { index in
                content = contents[index]
            }))

            _Button(
                content: content,
                buttonState: buttonState,
                size: size,
                horizontalLayout: horLayout,
                cornerStyle: cornerStyle,
                styleType: styleType,
                action: { print("action") }
            )
        }
        .padding()
    }

    func makePicker(title: String, from: [String], selection: Binding<Int>) -> some View {
        VStack(spacing: 4) {
            Text(title)

            PickerView(contents: from, selection: selection)
        }
    }
}

private let demoIcon = Assets.crossedEyeIcon.image
