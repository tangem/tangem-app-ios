//
//  FloatingSheetView.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

public struct FloatingSheetView: View {
    private let viewModel: (any FloatingSheetContentViewModel)?
    private let dismissSheetAction: () -> Void

    @State private var sheetContentHeight = CGFloat.zero
    @State private var sheetContentHasAppeared = false
    @State private var sheetContentConfiguration = FloatingSheetConfiguration.default

    @State private var keyboardHeight: CGFloat = 0
    @State private var verticalDragAmount: CGFloat = 0
    @GestureState private var isDragging = false

    @Environment(\.floatingSheetRegistry) private var registry: FloatingSheetRegistry

    public init(viewModel: (any FloatingSheetContentViewModel)?, dismissSheetAction: @escaping () -> Void) {
        self.viewModel = viewModel
        self.dismissSheetAction = dismissSheetAction
    }

    public var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                backgroundView
                sheetContent(proxy)
            }
            .if(sheetContentConfiguration.isBackgroundAndSheetSwipeEnabled) {
                $0.gesture(verticalSwipeGesture)
            }
        }
        .ignoresSafeArea(.all, edges: .bottom)
        .if(sheetContentConfiguration.keyboardHandlingEnabled) { view in
            view.keyboardHeight(bindTo: $keyboardHeight)
        }
        .onChange(of: isDragging) { _ in
            // [REDACTED_USERNAME], this may happed when DragGesture got canceled and onEnded block was not executed
            let stoppedDraggingAndOffsetHasNotBeenReset = !isDragging && verticalDragAmount != .zero
            guard stoppedDraggingAndOffsetHasNotBeenReset else { return }
            verticalDragAmount = .zero
        }
    }

    private var backgroundView: some View {
        BackgroundViewRepresentable()
            .opacity(viewModel == nil ? .zero : 1)
            .ignoresSafeArea()
            .allowsHitTesting(sheetContentConfiguration.backgroundInteractionBehavior != .passTouchesThrough)
            .onTapGesture {
                guard sheetContentConfiguration.backgroundInteractionBehavior == .tapToDismiss, !isDragging else { return }
                dismissSheetAction()
            }
            .if(sheetContentConfiguration.isBackgroundSwipeEnabled) {
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
                        .frame(
                            height: min(sheetContentHeight, bottomSheetMaxHeight(proxy: proxy)),
                            alignment: .bottom
                        )
                        .frame(maxWidth: .infinity)
                        .background {
                            sheetContent
                                .fixedSize(horizontal: false, vertical: true)
                                .hidden()
                                .readGeometry(\.size.height, bindTo: $sheetContentHeight)
                        }
                        .background(sheetContentConfiguration.sheetBackgroundColor)
                        .contentShape(roundedRectangle)
                        .clipShape(roundedRectangle)
                        .padding(.horizontal, 8)
                        .padding(.bottom, bottomSheetPadding)
                        .padding(.bottom, keyboardHeight)
                        .offset(y: verticalDragAmount)
                        .animation(.keyboard, value: keyboardHeight)
                        .animation(.floatingSheet, value: verticalDragAmount)
                        .if(sheetContentConfiguration.isSheetSwipeEnabled) {
                            $0.gesture(verticalSwipeGesture)
                        }
                        .id(viewModel.id)
                        .transition(.slideFromBottom)
                        .onAppear {
                            DispatchQueue.main.async {
                                sheetContentHasAppeared = true
                            }
                        }
                        .onDisappear {
                            sheetContentHasAppeared = false
                        }
                }
                .onPreferenceChange(FloatingSheetConfigurationPreferenceKey.self) { sheetContentConfiguration in
                    self.sheetContentConfiguration = sheetContentConfiguration
                }
                .frame(maxHeight: proxy.size.height * sheetContentConfiguration.maxHeightFraction, alignment: .bottom)
                .transition(.slideFromBottom)
            }
        }
        .animation(sheetContentHasAppeared ? sheetContentConfiguration.sheetFrameUpdateAnimation : nil, value: sheetContentHeight)
        .animation(.floatingSheet, value: viewModel?.id)
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
                if let threshold = sheetContentConfiguration.verticalSwipeBehavior?.threshold, dragGestureValue.translation.height > threshold {
                    dismissSheetAction()
                }

                verticalDragAmount = .zero
            }
    }

    private var roundedRectangle: some InsettableShape {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
    }

    private var bottomSheetPadding: CGFloat {
        let keyboardIsHidden = keyboardHeight == .zero

        guard Layout.deviceWithoutPhysicalHomeButton, keyboardIsHidden else {
            return 8
        }

        return 32
    }

    private func bottomSheetMaxHeight(proxy: GeometryProxy) -> CGFloat {
        let visibleHeight = proxy.size.height + proxy.safeAreaInsets.top
        let maxHeight = visibleHeight * sheetContentConfiguration.maxHeightFraction
        let maxWithKeyboardHeight = proxy.size.height - keyboardHeight - bottomSheetPadding
        let isKeyboardShowing = keyboardHeight > 0

        // When keyboard is showing the max height will be limited the top safe area
        return isKeyboardShowing ? maxWithKeyboardHeight : maxHeight
    }
}

private enum Layout {
    static let deviceWithoutPhysicalHomeButton = UIDevice.current.hasHomeScreenIndicator
}

private extension Animation {
    static let dimmedBackground = Animation.timingCurve(0.65, 0, 0.35, 1, duration: 0.2)
    static let floatingSheet = Animation.timingCurve(0.28, 0.02, 0.35, 1, duration: 0.3)
}

private extension AnyTransition {
    static let slideFromBottom = AnyTransition.move(edge: .bottom)
}

/// A ``UIView`` wrapper that allows ``TangemUIUtils.PassthroughWindow.hitTest(_:with:)`` method to work properly in iOS 26.0, *.
private struct BackgroundViewRepresentable: UIViewRepresentable {
    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            false
        }
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor(Colors.Overlays.overlaySecondary)

        let anyGestureRecognizer = UITapGestureRecognizer()
        anyGestureRecognizer.delegate = context.coordinator
        view.addGestureRecognizer(anyGestureRecognizer)

        return view
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
