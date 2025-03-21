//
//  FloatingSheetView.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

public struct FloatingSheetView<HostContent: View, SheetContent: View>: View {
    @Binding var isPresented: Bool
    let hostContent: HostContent
    let sheetContent: SheetContent

    @Environment(\.floatingSheetConfiguration) private var configuration: FloatingSheetConfiguration

    @State private var keyboardHeight: CGFloat = 0
    @State private var verticalDragAmount: CGFloat = 0
    @GestureState private var isDragging = false

    init(isPresented: Binding<Bool>, hostContent: HostContent, @ViewBuilder sheetContent: () -> SheetContent) {
        _isPresented = isPresented
        self.hostContent = hostContent
        self.sheetContent = sheetContent()
    }

    public var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                hostContent

                backgroundView
                    .animation(.dimmedBackground, value: isPresented)

                sheetContent(proxy)
                    .animation(.floatingSheet, value: isPresented)
            }
            .modifier(if: configuration.isBackgroundAndSheetSwipeEnabled) {
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

    @ViewBuilder
    private var backgroundView: some View {
        // [REDACTED_TODO_COMMENT]
        Color(white: .zero, opacity: isPresented ? 0.7 : .zero)
            .allowsHitTesting(configuration.backgroundInteractionBehavior != .passTouchesThrough)
            .onTapGesture {
                guard configuration.backgroundInteractionBehavior == .tapToDismiss, !isDragging else { return }
                isPresented = false
            }
            .modifier(if: configuration.isBackgroundSwipeEnabled) {
                $0.gesture(verticalSwipeGesture)
            }
    }

    @ViewBuilder
    private func sheetContent(_ proxy: GeometryProxy) -> some View {
        if isPresented {
            ZStack {
                sheetContent
                    .frame(minHeight: proxy.size.height * configuration.minHeightFraction, alignment: .bottom)
                    .background(configuration.sheetBackgroundColor)
                    .clipShape(roundedRectangle)
                    .frame(
                        maxHeight: proxy.size.height * configuration.maxHeightFraction,
                        alignment: .bottom
                    )
                    .clipShape(roundedRectangle)
                    .contentShape(roundedRectangle)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 34)
                    .padding(.bottom, keyboardHeight)
                    .offset(y: verticalDragAmount)
                    .animation(.floatingSheet, value: verticalDragAmount)
                    .animation(.keyboard, value: keyboardHeight)
                    .modifier(if: configuration.isSheetSwipeEnabled) {
                        $0.gesture(verticalSwipeGesture)
                    }
            }
            .transition(.move(edge: .bottom))
        }
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
                    isPresented = false
                }

                verticalDragAmount = .zero
            }
    }

    private var roundedRectangle: some Shape {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
    }
}

private extension Animation {
    static let dimmedBackground = Animation.timingCurve(0.65, 0, 0.35, 1, duration: 0.2)
    static let floatingSheet = Animation.timingCurve(0.28, 0.02, 0.35, 1, duration: 0.3)
}
