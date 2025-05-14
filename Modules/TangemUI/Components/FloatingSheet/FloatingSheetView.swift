//
//  FloatingSheetView.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

public struct FloatingSheetView<HostContent: View>: View {
    private let hostContent: HostContent
    private let viewModel: (any FloatingSheetContentViewModel)?
    private let dismissSheetAction: () -> Void

    @State private var keyboardHeight: CGFloat = 0
    @State private var verticalDragAmount: CGFloat = 0
    @GestureState private var isDragging = false

    @Environment(\.floatingSheetRegistry) private var registry: FloatingSheetRegistry
    @Environment(\.floatingSheetConfiguration) private var configuration: FloatingSheetConfiguration

    public init(hostContent: HostContent, viewModel: (any FloatingSheetContentViewModel)?, dismissSheetAction: @escaping () -> Void) {
        self.hostContent = hostContent
        self.viewModel = viewModel
        self.dismissSheetAction = dismissSheetAction
    }

    public var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                hostContent

                backgroundView

                sheetContent(proxy)
            }
            .if(configuration.isBackgroundAndSheetSwipeEnabled) {
                $0.gesture(verticalSwipeGesture)
            }
        }
        .ignoresSafeArea()
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            guard
                configuration.keyboardHandlingEnabled,
                let userInfo = notification.userInfo,
                let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
            else {
                return
            }

            keyboardHeight = keyboardFrame.height
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardHeight = .zero
        }
        .onChange(of: isDragging) { _ in
            // [REDACTED_USERNAME], this may happed when DragGesture got canceled and onEnded block was not executed
            let stoppedDraggingAndOffsetHasNotBeenReset = !isDragging && verticalDragAmount != .zero
            guard stoppedDraggingAndOffsetHasNotBeenReset else { return }
            verticalDragAmount = .zero
        }
    }

    private var backgroundView: some View {
        Colors.Overlays.overlaySecondary
            .opacity(viewModel == nil ? .zero : 1)
            .allowsHitTesting(configuration.backgroundInteractionBehavior != .passTouchesThrough)
            .onTapGesture {
                guard configuration.backgroundInteractionBehavior == .tapToDismiss, !isDragging else { return }
                dismissSheetAction()
            }
            .if(configuration.isBackgroundSwipeEnabled) {
                $0.gesture(verticalSwipeGesture)
            }
            .animation(.dimmedBackground, value: viewModel == nil)
    }

    @ViewBuilder
    private func sheetContent(_ proxy: GeometryProxy) -> some View {
        ZStack {
            if let viewModel, let sheetContent = registry.view(for: viewModel) {
                ZStack {
                    sheetContent
                        .frame(minHeight: proxy.size.height * configuration.minHeightFraction, alignment: .top)
                        .background(configuration.sheetBackgroundColor)
                        .clipShape(roundedRectangle)
                        .contentShape(roundedRectangle)
                        .frame(
                            maxHeight: proxy.size.height * configuration.maxHeightFraction,
                            alignment: .bottom
                        )
                        .clipShape(roundedRectangle)
                        .padding(.horizontal, 8)
                        .padding(.bottom, bottomSheetPadding)
                        .offset(y: verticalDragAmount)
                        .animation(.floatingSheet, value: verticalDragAmount)
                        .if(configuration.isSheetSwipeEnabled) {
                            $0.gesture(verticalSwipeGesture)
                        }
                        .id(viewModel.id)
                        .transition(.slideFromBottom)
                }
                .animation(.floatingSheet, value: viewModel.id)
                .transition(.slideFromBottom)
            }
        }
        .offset(y: -keyboardHeight)
        .animation(.keyboard, value: keyboardHeight)
        .animation(.floatingSheet, value: viewModel == nil)
    }

    private var verticalSwipeGesture: some Gesture {
        DragGesture()
            .updating($isDragging) { _, state, _ in
                state = true
            }
            .onChanged { dragGestureValue in
                verticalDragAmount = max(.zero, dragGestureValue.translation.height)
            }
            .onEnded { dragGestureValue in
                if let threshold = configuration.verticalSwipeBehavior?.threshold, dragGestureValue.translation.height > threshold {
                    dismissSheetAction()
                }

                verticalDragAmount = .zero
            }
    }

    private var roundedRectangle: some Shape {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
    }

    private var bottomSheetPadding: CGFloat {
        let keyboardIsVisible = keyboardHeight > 0
        return keyboardIsVisible
            ? 12
            : 32
    }
}

private extension Animation {
    static let dimmedBackground = Animation.timingCurve(0.65, 0, 0.35, 1, duration: 0.2)
    static let floatingSheet = Animation.timingCurve(0.28, 0.02, 0.35, 1, duration: 0.3)
}

private extension AnyTransition {
    static let slideFromBottom = AnyTransition.move(edge: .bottom)
}
