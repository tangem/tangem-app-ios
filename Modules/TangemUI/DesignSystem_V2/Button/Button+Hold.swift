//
//  Button+Hold.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUIUtils

// MARK: - Public types

public extension Button {
    enum HoldStyle: Hashable, Sendable, CaseIterable {
        case brand
        case primary

        var styleType: StyleType {
            switch self {
            case .brand: .brand
            case .primary: .primary
            }
        }
    }

    static func holdToConfirm(
        label: String,
        style: HoldStyle,
        accessibilityLabel: String?,
        size: Size = .x10,
        horizontalLayout: HorizontalLayout = .intrinsic,
        iconStart: ImageType? = nil,
        iconEnd: ImageType? = nil,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        HoldBody(
            base: Button(label: label, accessibilityLabel: nil, action: {})
                .iconStart(iconStart)
                .iconEnd(iconEnd)
                .size(size)
                .styleType(style.styleType)
                .horizontalLayout(horizontalLayout)
                .loading(.spinner(if: isLoading)),
            configuration: .default,
            isLoading: isLoading,
            accessibilityLabel: accessibilityLabel ?? label,
            action: action
        )
    }
}

// MARK: - Internal types

extension Button {
    struct HoldConfiguration: Hashable {
        let cancelHint: String
        let holdDuration: TimeInterval
        let shakeDuration: TimeInterval

        static let `default` = HoldConfiguration(
            cancelHint: Localization.commonTapAndHoldHint,
            holdDuration: 2,
            shakeDuration: 0.24
        )
    }

    struct HoldFill: Equatable {
        let isFilled: Bool
        let isPulsing: Bool
        let isCompleted: Bool
        let animation: Animation?
    }

    enum HoldMotion {
        static let release: Animation = .easeOut(duration: 0.24)
        static let pulseHalfDuration: TimeInterval = 0.1
        static let pulse: Animation = .timingCurve(0.5, 0, 0.5, 1, duration: pulseHalfDuration)
        static let completion: Animation = .timingCurve(0.5, 0, 0.5, 1, duration: 0.05)
        static let shakeTravelDistance: CGFloat = -8
    }
}

// MARK: - Body

extension Button {
    struct HoldBody: View {
        private let base: Button
        private let configuration: HoldConfiguration
        private let isLoading: Bool
        private let accessibilityLabel: String
        private let action: HoldAction

        @Environment(\.isEnabled) private var isEnabled
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        @StateObject private var model: ButtonHoldModel

        init(
            base: Button,
            configuration: HoldConfiguration,
            isLoading: Bool,
            accessibilityLabel: String,
            action: @escaping () -> Void
        ) {
            self.base = base
            self.configuration = configuration
            self.isLoading = isLoading
            self.accessibilityLabel = accessibilityLabel
            self.action = HoldAction(closure: action)
            _model = StateObject(
                wrappedValue: ButtonHoldModel(
                    isLoading: isLoading,
                    isDisabled: false,
                    configuration: configuration,
                    action: action
                )
            )
        }

        var body: some View {
            displayedBase
                .accessibilityHidden(true)
                .environment(\.buttonHoldFill, holdFill)
                .animation(HoldMotion.completion, value: model.isCompleted)
                .allowsHitTesting(false)
                .transaction { $0.animation = nil }
                .overlay { touchArea }
                .shake(
                    trigger: reduceMotion ? 0 : model.shakeTrigger,
                    duration: model.shakeDuration,
                    shakesPerUnit: 1,
                    travelDistance: HoldMotion.shakeTravelDistance
                )
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(model.showsCancelHint ? configuration.cancelHint : accessibilityLabel))
                .accessibilityHint(Text(configuration.cancelHint))
                .accessibilityValue(Text(model.isCompleted ? Localization.commonInProgress : ""))
                .accessibilityAddTraits(.isButton)
                .onAppear {
                    if !isEnabled {
                        model.onDisabledChanged(isDisabled: true)
                    }
                }
                .onChange(of: isLoading, perform: model.onLoadingChanged)
                .onChange(of: isEnabled) { model.onDisabledChanged(isDisabled: !$0) }
                .onChange(of: configuration, perform: model.onConfigurationChanged)
                .onChange(of: action) { model.onActionChanged(action: $0.closure) }
        }

        private var displayedBase: Button {
            if model.showsCancelHint {
                return base.labelText(configuration.cancelHint)
            }

            if model.state == .confirmed {
                return base.loading(.spinner)
            }

            return base
        }

        private var holdFill: HoldFill {
            HoldFill(
                isFilled: model.isFilled,
                isPulsing: model.isPulsing,
                isCompleted: model.isCompleted,
                animation: fillAnimation
            )
        }

        private var fillAnimation: Animation? {
            switch model.state {
            case .holding: .linear(duration: model.holdDuration)
            case .canceled: HoldMotion.release
            case .idle, .confirmed, .loading: nil
            }
        }

        @ViewBuilder
        private var touchArea: some View {
            if model.acceptsTouches {
                Color.clear.onTouches(perform: model.onTouches)
            }
        }
    }

    struct HoldAction: Equatable {
        private let id = UUID()

        let closure: () -> Void

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.id == rhs.id
        }
    }
}

// MARK: - Environment

extension EnvironmentValues {
    @Entry var buttonHoldFill: Button.HoldFill? = nil
}
