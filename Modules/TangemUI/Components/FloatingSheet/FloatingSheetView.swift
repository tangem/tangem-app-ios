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
    @State private var renderedViewModel: (any FloatingSheetContentViewModel)?

    private let dismissSheetAction: () -> Void

    @State private var sheetContentConfiguration = FloatingSheetConfiguration.default
    @State private var isSheetFrameUpdateAnimationEnabled = false

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
                sheetContainer(proxy)
            }
            .if(sheetContentConfiguration.isBackgroundAndSheetSwipeEnabled) {
                $0.gesture(verticalSwipeGesture)
            }
        }
        .ignoresSafeArea(.all, edges: .bottom)
        .if(sheetContentConfiguration.keyboardHandlingEnabled) { view in
            view.keyboardHeight(bindTo: $keyboardHeight)
        }
        .onPreferenceChange(FloatingSheetConfigurationPreferenceKey.self) { sheetContentConfiguration in
            self.sheetContentConfiguration = sheetContentConfiguration
        }
        .onChange(of: isDragging) { _ in
            let stoppedDraggingAndOffsetHasNotBeenReset = !isDragging && verticalDragAmount != .zero
            guard stoppedDraggingAndOffsetHasNotBeenReset else { return }
            verticalDragAmount = .zero
        }
        .task(id: viewModel?.id) {
            if let viewModel {
                await showRenderedSheet(viewModel)
            } else {
                hideRenderedSheet()
            }
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

    private func sheetContainer(_ proxy: GeometryProxy) -> some View {
        ZStack {
            sheet(proxy)
        }
        .animation(.floatingSheet, value: viewModel?.id)
    }

    @ViewBuilder
    private func sheet(_ proxy: GeometryProxy) -> some View {
        if let renderedViewModel, let sheetContent = registry.view(for: renderedViewModel) {
            FloatingSheetLayout(maxHeight: sheetMaxHeight(proxy)) {
                sheetContent
                    .transaction { transaction in
                        guard isSheetFrameUpdateAnimationEnabled else { return }
                        transaction.animation = nil
                    }
            }
            .background(sheetContentConfiguration.sheetBackgroundColor)
            .clipShape(roundedRectangle)
            .contentShape(roundedRectangle)
            .padding(.horizontal, 8)
            .padding(.bottom, bottomSheetPadding)
            .padding(.bottom, keyboardHeight)
            .offset(y: verticalDragAmount)
            .animation(.keyboard, value: keyboardHeight)
            .animation(.floatingSheet, value: verticalDragAmount)
            .gesture(verticalSwipeGesture, isEnabled: sheetContentConfiguration.isSheetSwipeEnabled)
            .transaction { transaction in
                guard isSheetFrameUpdateAnimationEnabled else { return }
                transaction.animation = sheetContentConfiguration.sheetFrameUpdateAnimation
            }
            .accessibilityElement(children: .contain)
            .accessibilityAddTraits(.isModal)
            .transition(.move(edge: .bottom))
            .id(renderedViewModel.id)
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

    private func sheetMaxHeight(_ proxy: GeometryProxy) -> CGFloat {
        let visibleHeight = proxy.size.height + proxy.safeAreaInsets.top
        let maxHeight = visibleHeight * sheetContentConfiguration.maxHeightFraction
        let maxWithKeyboardHeight = proxy.size.height - keyboardHeight - bottomSheetPadding
        let isKeyboardShowing = keyboardHeight > 0

        // When keyboard is showing the max height will be limited the top safe area
        return isKeyboardShowing ? maxWithKeyboardHeight : maxHeight
    }

    private func showRenderedSheet(_ viewModel: some FloatingSheetContentViewModel) async {
        isSheetFrameUpdateAnimationEnabled = false
        withAnimation(.floatingSheet) {
            renderedViewModel = viewModel
        }

        try? await Task.sleep(for: .seconds(Animation.sheetAppearanceDuration))

        guard !Task.isCancelled, renderedViewModel?.id == viewModel.id else { return }
        isSheetFrameUpdateAnimationEnabled = true
    }

    private func hideRenderedSheet() {
        isSheetFrameUpdateAnimationEnabled = false

        guard renderedViewModel != nil else { return }

        withAnimation(.floatingSheet) {
            renderedViewModel = nil
        }
    }
}

private enum Layout {
    static let deviceWithoutPhysicalHomeButton = UIDevice.current.hasHomeScreenIndicator
}

private extension Animation {
    static let sheetAppearanceDuration: TimeInterval = 0.3

    static let dimmedBackground = Animation.timingCurve(0.65, 0, 0.35, 1, duration: 0.2)
    static let floatingSheet = Animation.timingCurve(0.28, 0.02, 0.35, 1, duration: sheetAppearanceDuration)
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

private struct FloatingSheetLayout: SwiftUI.Layout {
    let maxHeight: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        guard let content = subviews.first else { return .zero }

        let idealSize = content.sizeThatFits(ProposedViewSize(width: proposal.width, height: nil))

        return CGSize(width: proposal.width ?? idealSize.width, height: min(idealSize.height, maxHeight))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        guard let content = subviews.first else { return }

        content.place(at: bounds.origin, anchor: .topLeading, proposal: ProposedViewSize(width: bounds.width, height: bounds.height))
    }
}
