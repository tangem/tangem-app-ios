//
//  BottomScrollableSheetStateObject.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

// [REDACTED_TODO_COMMENT]
public class BottomScrollableSheetStateObject: ObservableObject {
    @Published var visibleHeight: CGFloat = 0
    @Published var scrollViewIsDragging: Bool = false
    @Published var headerSize: CGFloat = 0

    var geometryInfoSubject: some Subject<GeometryInfo, Never> { _geometryInfoSubject }
    private let _geometryInfoSubject = CurrentValueSubject<GeometryInfo, Never>(.zero)
    private var geometryInfo: GeometryInfo { _geometryInfoSubject.value }

    // [REDACTED_TODO_COMMENT]
    var percent: CGFloat {
        let maxHeight = height(for: .top)
        let minHeight = height(for: .bottom)
        return clamp((visibleHeight - minHeight) / maxHeight, min: 0.0, max: 1.0)
    }

    private var state: SheetState = .bottom
    private var contentOffset: CGPoint = .zero
    private var keyboardCancellable: AnyCancellable?

    public init() {
        bindKeyboard()
    }

    func onAppear() {
        updateToState(state)
    }

    /// Use for set and update sheet to the state
    func updateToState(_ state: SheetState) {
        self.state = state

        withAnimation(.easeOut) {
            visibleHeight = height(for: state)
        }
    }

    /// Use for change height when user is dragging
    func updateVisibleHeight(_ height: CGFloat) {
        withAnimation(.interactiveSpring()) {
            self.visibleHeight = height
        }
    }

    func height(for state: BottomScrollableSheetStateObject.SheetState) -> CGFloat {
        switch state {
        case .bottom:
            return headerSize
        case .top:
            return geometryInfo.size.height + geometryInfo.safeAreaInsets.bottom
        }
    }

    // MARK: Gestures

    func headerDragGesture(onChanged value: DragGesture.Value) {
        UIApplication.shared.endEditing()
        dragView(translation: value.translation.height)
    }

    func headerDragGesture(onEnded value: DragGesture.Value) {
        let hidingLine = height(for: .top) * Constants.hidingLineMultiplicator

        // If the ended location below the hiding line
        if value.predictedEndLocation.y > hidingLine {
            updateToState(.bottom)
        } else {
            updateToState(.top)
        }
    }

    func scrollViewContentDragGesture(onChanged value: UIPanGestureRecognizer.Value) {
        UIApplication.shared.endEditing()

        let translationChange = value.translation.height
        let isFromTop = contentOffset.y <= .zero
        let isBottomDirection = translationChange > 0
        if isFromTop, isBottomDirection, !scrollViewIsDragging {
            scrollViewIsDragging = true
        }

        if scrollViewIsDragging {
            dragView(translation: translationChange)
        }
    }

    func scrollViewContentDragGesture(onEnded value: UIPanGestureRecognizer.Value) {
        // If the dragging was started from the top of the ScrollView
        if contentOffset.y <= .zero {
            // The user made a quick enough swipe to hide sheet
            let isHighVelocity = value.velocity.y > geometryInfo.size.height

            // The user stop swipe below hiding line
            let hidingLine = height(for: .top) * Constants.hidingLineMultiplicator
            let isStoppedBelowHidingLine = visibleHeight < hidingLine

            if isHighVelocity || isStoppedBelowHidingLine {
                updateToState(.bottom)
            } else {
                updateToState(.top)
            }
        }

        if scrollViewIsDragging {
            scrollViewIsDragging = false
        }
    }

    private func bindKeyboard() {
        keyboardCancellable = NotificationCenter
            .default
            .publisher(for: UIResponder.keyboardWillShowNotification)
            .sink { [weak self] _ in
                self?.updateToState(.top)
            }
    }

    private func dragView(translation: CGFloat) {
        var translationChange = translation

        switch state {
        case .top:
            // For the top state reduce the direction to bottom
            if translationChange < 0 {
                translationChange /= Constants.reduceSwipeMultiplicator
            }
        case .bottom:
            // For the bottom state reduce the direction to top
            if translationChange > 0 {
                translationChange /= Constants.reduceSwipeMultiplicator
            }
        }

        let newHeight = height(for: state) - translationChange
        updateVisibleHeight(newHeight)
    }
}

extension BottomScrollableSheetStateObject: ScrollViewRepresentableDelegate {
    func getSafeAreaInsets() -> UIEdgeInsets {
        UIEdgeInsets(
            top: .zero,
            left: .zero,
            bottom: geometryInfo.safeAreaInsets.bottom,
            right: .zero
        )
    }

    func contentOffsetDidChanged(contentOffset: CGPoint) {
        self.contentOffset = contentOffset
    }

    func gesture(onChanged value: UIPanGestureRecognizer.Value) {
        scrollViewContentDragGesture(onChanged: value)
    }

    func gesture(onEnded value: UIPanGestureRecognizer.Value) {
        scrollViewContentDragGesture(onEnded: value)
    }
}

extension BottomScrollableSheetStateObject {
    enum Constants {
        static let hidingLineMultiplicator: CGFloat = 0.5
        static let reduceSwipeMultiplicator: CGFloat = 10
    }

    enum SheetState: String, Hashable {
        case top
        case bottom
    }
}
