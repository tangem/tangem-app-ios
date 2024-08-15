//
//  OverlayContentContainerViewController.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

final class OverlayContentContainerViewController: UIViewController {
    // MARK: - Dependencies

    private let contentViewController: UIViewController
    private let overlayCollapsedHeight: CGFloat
    private let overlayExpandedVerticalOffset: CGFloat
    private var overlayCollapsedVerticalOffset: CGFloat { screenBounds.height - overlayCollapsedHeight }

    // MARK: - Mutable state

    private var overlayViewController: UIViewController?
    private var panGestureStartLocationInScreenCoordinateSpace: CGPoint = .zero
    private var panGestureStartLocationInOverlayViewCoordinateSpace: CGPoint = .zero
    private var shouldIgnorePanGestureRecognizer = false
    private var didTap = false
    private var scrollViewContentOffsetLocker: ScrollViewContentOffsetLocker?

    private var progress: CGFloat = .zero {
        didSet { onProgressChange(oldValue: oldValue, newValue: progress) }
    }

    private var stateObservers: [AnyHashable: OverlayContentStateObserver.Observer] = [:]

    // MARK: - Read-only state

    private var screenBounds: CGRect {
        return UIScreen.main.bounds
    }

    private var adjustedContentOffset: CGPoint {
        return scrollViewContentOffsetLocker?.scrollView.adjustedContentOffset ?? .zero
    }

    private var isExpandedState: Bool {
        return abs(1.0 - progress) <= .ulpOfOne
    }

    private var isCollapsedState: Bool {
        return abs(progress) <= .ulpOfOne
    }

    /// I.e. either collapsed or expanded.
    private var isFinalState: Bool {
        return isExpandedState || isCollapsedState
    }

    // MARK: - IBOutlets/UI

    private var overlayViewTopAnchorConstraint: NSLayoutConstraint?
    private lazy var backgroundShadowView = UIView(frame: screenBounds)
    private lazy var tapGestureRecognizerHostingView = TouchPassthroughView()

    // MARK: - Helpers

    private lazy var appLifecycleHelper = OverlayContentContainerAppLifecycleHelper()

    // MARK: - Initialization/Deinitialization

    /// - Note: All height/offset parameters (`overlayCollapsedHeight`, `overlayExpandedVerticalOffset`, etc)
    /// are relative to the main screen bounds (w/o safe area).
    init(
        contentViewController: UIViewController,
        overlayCollapsedHeight: CGFloat,
        overlayExpandedVerticalOffset: CGFloat
    ) {
        self.contentViewController = contentViewController
        self.overlayCollapsedHeight = overlayCollapsedHeight
        self.overlayExpandedVerticalOffset = overlayExpandedVerticalOffset
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable, message: "init(coder:) has not been implemented")
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        // The order in which all these methods are called matters, change it with caution
        setupView()
        setupTapGestureRecognizer()
        setupPanGestureRecognizer()
        setupContent()
        setupBackgroundShadowView()
        setupTapGestureRecognizerHostingView()
        setupOverlayIfAvailable()
        setupAppLifecycleHelper()
    }

    // MARK: - Public API

    func installOverlay(_ newOverlayViewController: UIViewController) {
        guard overlayViewController == nil else {
            assertionFailure("Remove previous overlay view controller using `removeOverlay` before installing a new one")
            return
        }

        guard isViewLoaded else {
            // Overlay (if any) will be installed in `viewDidLoad` later on
            return
        }

        overlayViewController = newOverlayViewController
        setupOverlay(newOverlayViewController)
    }

    func removeOverlay() {
        guard let overlayViewController else {
            return
        }

        reset() // Crucial for tearing down the KVO observation (if any)

        overlayViewController.willMove(toParent: nil)

        overlayViewTopAnchorConstraint?.isActive = false
        overlayViewTopAnchorConstraint = nil

        let overlayView = overlayViewController.view!
        overlayView.removeFromSuperview()

        overlayViewController.removeFromParent()
        self.overlayViewController = nil
        progress = 0.0
    }

    /// - Warning: This method maintains strong reference to the given `observer` closure.
    /// Remove this reference by using `removeObserver(forToken:)` method.
    func addObserver(_ observer: @escaping OverlayContentStateObserver.Observer, forToken token: any Hashable) {
        stateObservers[AnyHashable(token)] = observer
    }

    func removeObserver(forToken token: any Hashable) {
        stateObservers.removeValue(forKey: AnyHashable(token))
    }

    func expand() {
        overlayViewTopAnchorConstraint?.constant = overlayExpandedVerticalOffset
        UIView.animate(withDuration: Constants.defaultAnimationDuration) { // [REDACTED_TODO_COMMENT]
            self.view.layoutIfNeeded()
            self.progress = 1.0
        }
    }

    func collapse() {
        overlayViewTopAnchorConstraint?.constant = overlayCollapsedVerticalOffset
        UIView.animate(withDuration: Constants.defaultAnimationDuration) { // [REDACTED_TODO_COMMENT]
            self.view.layoutIfNeeded()
            self.progress = 0.0
        }
    }

    // MARK: - Setup

    private func setupView() {
        view.backgroundColor = .black
    }

    /// - Note: The order in which this method is called matters. Must be called between `setupContent` and `setupOverlay`.
    private func setupBackgroundShadowView() {
        // [REDACTED_TODO_COMMENT]
        backgroundShadowView.backgroundColor = .black
        backgroundShadowView.alpha = Constants.minBackgroundShadowViewAlpha
        backgroundShadowView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundShadowView.isUserInteractionEnabled = false
        view.addSubview(backgroundShadowView)
    }

    private func setupContent() {
        addChild(contentViewController)

        let containerView = view!
        let contentView = contentViewController.view!
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(contentView)

        NSLayoutConstraint.activate([
            contentView.heightAnchor.constraint(equalToConstant: screenBounds.height),
            contentView.widthAnchor.constraint(equalToConstant: screenBounds.width),
        ])

        contentView.layer.cornerRadius = Constants.cornerRadius // [REDACTED_TODO_COMMENT]
        contentView.layer.masksToBounds = true

        contentViewController.didMove(toParent: self)
    }

    private func setupOverlayIfAvailable() {
        if let overlayViewController {
            setupOverlay(overlayViewController)
        }
    }

    private func setupOverlay(_ overlayViewController: UIViewController) {
        addChild(overlayViewController)

        let containerView = view!
        let overlayView = overlayViewController.view!
        containerView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        // `overlayView` always must be placed under `tapGestureRecognizerHostingView`
        containerView.insertSubview(overlayView, belowSubview: tapGestureRecognizerHostingView)

        let overlayViewTopAnchorConstraint = overlayView
            .topAnchor
            .constraint(equalTo: containerView.topAnchor, constant: overlayCollapsedVerticalOffset)
        self.overlayViewTopAnchorConstraint = overlayViewTopAnchorConstraint

        NSLayoutConstraint.activate([
            overlayViewTopAnchorConstraint,
            overlayView.heightAnchor.constraint(equalToConstant: screenBounds.height - overlayExpandedVerticalOffset),
            overlayView.widthAnchor.constraint(equalToConstant: screenBounds.width),
        ])

        overlayView.layer.cornerRadius = Constants.cornerRadius
        overlayView.layer.masksToBounds = true

        overlayViewController.didMove(toParent: self)
    }

    private func setupTapGestureRecognizerHostingView() {
        tapGestureRecognizerHostingView.delegate = self
        tapGestureRecognizerHostingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tapGestureRecognizerHostingView)
        NSLayoutConstraint.activate([
            tapGestureRecognizerHostingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tapGestureRecognizerHostingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tapGestureRecognizerHostingView.topAnchor.constraint(equalTo: view.topAnchor),
            tapGestureRecognizerHostingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupTapGestureRecognizer() {
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onTapGesture(_:)))
        tapGestureRecognizerHostingView.addGestureRecognizer(gestureRecognizer)
    }

    private func setupPanGestureRecognizer() {
        let gestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(onPanGesture(_:)))
        gestureRecognizer.delegate = self
        view.addGestureRecognizer(gestureRecognizer)
    }

    private func setupAppLifecycleHelper() {
        appLifecycleHelper.delegate = self
        appLifecycleHelper.observeLifecycleIfNeeded()
    }

    // MARK: - State update

    private func updateProgress() {
        let verticalOffset = overlayViewTopAnchorConstraint?.constant ?? .zero

        progress = clamp(
            (overlayCollapsedVerticalOffset - verticalOffset) / (overlayCollapsedVerticalOffset - overlayExpandedVerticalOffset),
            min: 0.0,
            max: 1.0
        )
    }

    private func updateContentScale() {
        let contentLayer = contentViewController.view.layer
        let invertedProgress = 1.0 - progress
        let scale = Constants.minContentViewScale
            + (Constants.maxContentViewScale - Constants.minContentViewScale) * invertedProgress

        if isFinalState {
            let keyPath = String(_sel: #selector(getter: CALayer.transform)) // [REDACTED_TODO_COMMENT]
            let animation = CABasicAnimation(keyPath: keyPath)
            animation.duration = Constants.defaultAnimationDuration
            contentLayer.add(animation, forKey: #function)
        }

        let transform: CGAffineTransform = .scaleTransform(
            for: contentLayer.bounds.size,
            scaledBy: .init(x: scale, y: scale),
            aroundAnchorPoint: .init(x: 0.0, y: 1.0), // Bottom left corner
            translationCoefficient: Constants.contentViewTranslationCoefficient
        )

        contentLayer.setAffineTransform(transform)
    }

    private func updateBackgroundShadowViewAlpha() {
        let alpha = Constants.minBackgroundShadowViewAlpha
            + (Constants.maxBackgroundShadowViewAlpha - Constants.minBackgroundShadowViewAlpha) * progress

        if isFinalState {
            UIView.animate(withDuration: Constants.defaultAnimationDuration) { // [REDACTED_TODO_COMMENT]
                self.backgroundShadowView.alpha = alpha
            }
        } else {
            backgroundShadowView.alpha = alpha
        }
    }

    private func notifyStateObserversIfNeeded() {
        for stateObserver in stateObservers.values {
            if isCollapsedState {
                stateObserver(.bottom)
            } else if isExpandedState {
                let trigger: OverlayContentStateObserver.State.Trigger = didTap ? .tapGesture : .dragGesture
                stateObserver(.top(trigger: trigger))
            } else {
                // No-op
            }
        }
    }

    private func reset() {
        panGestureStartLocationInScreenCoordinateSpace = .zero
        panGestureStartLocationInOverlayViewCoordinateSpace = .zero
        shouldIgnorePanGestureRecognizer = false
        scrollViewContentOffsetLocker = nil
    }

    // MARK: - Handlers

    private func onProgressChange(oldValue: CGFloat, newValue: CGFloat) {
        guard oldValue != newValue else {
            return
        }

        updateContentScale()
        updateBackgroundShadowViewAlpha()
        notifyStateObserversIfNeeded()

        if didTap {
            didTap = false
        }
    }

    @objc
    private func onTapGesture(_ gestureRecognizer: UITapGestureRecognizer) {
        didTap = true
        expand()
    }

    @objc
    private func onPanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            if didTap {
                didTap = false
            }
        case .changed:
            onPanGestureChanged(gestureRecognizer)
        case .ended:
            onPanGestureEnded(gestureRecognizer)
        case .cancelled, .failed:
            reset()
        case .possible, .recognized:
            break
        @unknown default:
            assertionFailure("Unknown state received \(gestureRecognizer.state)")
        }
    }

    func onPanGestureChanged(_ gestureRecognizer: UIPanGestureRecognizer) {
        if shouldIgnorePanGestureRecognizer {
            return
        }

        let verticalDirection = verticalDirection(for: gestureRecognizer)

        switch verticalDirection {
        case _ where scrollViewContentOffsetLocker == nil:
            // There is no scroll view in the overlay view, use default logic
            break
        case .up where isExpandedState:
            // Normal scrolling to the bottom of the scroll view content, pan gesture recognizer should be ignored
            // for the entire duration of the gesture (until end)
            shouldIgnorePanGestureRecognizer = true
            return
        case .up where isCollapsedState:
            // Expanding overlay using pan gesture, the scroll view content offset should remain intact,
            // so we lock it and then use default logic
            scrollViewContentOffsetLocker?.lock()
        case .down where adjustedContentOffset.y <= Constants.minAdjustedContentOffsetToLockScrollView:
            // Collapsing overlay using pan gesture, the scroll view content offset should remain intact,
            // so we lock it and then use default logic
            scrollViewContentOffsetLocker?.lock()
        case .down where adjustedContentOffset != .zero && scrollViewContentOffsetLocker?.isLocked == false:
            // Normal scrolling to the top of the scroll view content, pan gesture recognizer should be ignored
            // for the entire duration of the gesture (until end)
            shouldIgnorePanGestureRecognizer = true
            return
        default:
            break
        }

        let translation = gestureRecognizer.translation(in: nil)
        let currentVerticalOffset = overlayViewTopAnchorConstraint?.constant ?? .zero
        let newVerticalOffset = clamp(
            currentVerticalOffset + translation.y,
            min: overlayExpandedVerticalOffset,
            max: overlayCollapsedVerticalOffset
        )
        overlayViewTopAnchorConstraint?.constant = newVerticalOffset // [REDACTED_TODO_COMMENT]
        gestureRecognizer.setTranslation(.zero, in: nil)

        updateProgress()
    }

    func onPanGestureEnded(_ gestureRecognizer: UIPanGestureRecognizer) {
        defer {
            reset()
        }

        if shouldIgnorePanGestureRecognizer {
            return
        }

        let velocity = gestureRecognizer.velocity(in: nil)
        let verticalDirection = verticalDirection(for: gestureRecognizer)
        let decelerationRate = calculateDecelerationRate(gestureVerticalDirection: verticalDirection)
        let predictedEndLocation = gestureRecognizer.predictedEndLocation(in: nil, atDecelerationRate: decelerationRate)
        let overlayViewFramePredictedOrigin = predictedEndLocation - panGestureStartLocationInOverlayViewCoordinateSpace
        let isCollapsing = overlayViewFramePredictedOrigin.y > screenBounds.height / 2.0

        let animationDuration = calculateAnimationDuration(
            isCollapsing: isCollapsing,
            gestureVelocity: velocity,
            gestureVerticalDirection: verticalDirection
        )

        let finalOffset = isCollapsing ? overlayCollapsedVerticalOffset : overlayExpandedVerticalOffset
        overlayViewTopAnchorConstraint?.constant = finalOffset

        UIView.animate(withDuration: animationDuration, delay: .zero, options: .curveEaseOut) {
            self.view.layoutIfNeeded()
        }

        updateProgress()
    }

    // MARK: - Helpers

    private func verticalDirection(for gestureRecognizer: UIPanGestureRecognizer) -> VerticalDirection? {
        let location = gestureRecognizer.location(in: nil)

        if panGestureStartLocationInScreenCoordinateSpace.y > location.y {
            return .up
        }

        if panGestureStartLocationInScreenCoordinateSpace.y < location.y {
            return .down
        }

        // Edge case (is it even possible?), unable to determine
        return nil
    }

    private func calculateDecelerationRate(
        gestureVerticalDirection: VerticalDirection?
    ) -> UIScrollView.DecelerationRate {
        // Makes the overlay view easier to expand and a bit harder to collapse
        switch gestureVerticalDirection {
        case .down:
            return .fast
        case .up,
             .none:
            return .normal
        }
    }

    private func calculateAnimationDuration(
        isCollapsing: Bool,
        gestureVelocity: CGPoint,
        gestureVerticalDirection: VerticalDirection?
    ) -> TimeInterval {
        // Equals `true` when a user tries to collapse or expand the overlay view with a pan gesture
        // but ultimately fails to do so (e.g., the velocity of the pan gesture is too low)
        let isGestureFailed = (isCollapsing && gestureVerticalDirection == .up)
            || (!isCollapsing && gestureVerticalDirection == .down)

        if isGestureFailed {
            // We don't take gesture velocity into account if the gesture fails
            return Constants.defaultAnimationDuration
        }

        let overlayViewFrame = overlayViewController?.view.frame ?? .zero

        let remainingDistance = isCollapsing
            ? max(screenBounds.height - overlayCollapsedHeight - overlayViewFrame.minY, .zero)
            : max(overlayViewFrame.minY - overlayExpandedVerticalOffset, .zero)

        return min(remainingDistance / abs(gestureVelocity.y), Constants.defaultAnimationDuration)
    }
}

// MARK: - UIGestureRecognizerDelegate protocol conformance

extension OverlayContentContainerViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let locationInScreenCoordinateSpace = touch.location(in: nil)

        panGestureStartLocationInScreenCoordinateSpace = locationInScreenCoordinateSpace
        panGestureStartLocationInOverlayViewCoordinateSpace = touch.location(in: overlayViewController?.view)

        // The gesture is completely disabled if no overlay view controller is set
        return overlayViewController?.view.frame.contains(locationInScreenCoordinateSpace) ?? false
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer else {
            return true
        }

        let velocity = panGestureRecognizer.velocity(in: nil)

        // Trigger pan-to-collapse logic only on a vertical pan gesture
        return abs(velocity.y) > abs(velocity.x)
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        if otherGestureRecognizer is UIPanGestureRecognizer, let scrollView = otherGestureRecognizer.view as? UIScrollView {
            scrollViewContentOffsetLocker = .make(for: scrollView)
        }

        return true
    }
}

// MARK: - TouchPassthroughViewDelegate protocol conformance

extension OverlayContentContainerViewController: TouchPassthroughViewDelegate {
    func touchPassthroughView(
        _ passthroughView: TouchPassthroughView,
        shouldPassthroughTouchAt point: CGPoint,
        with event: UIEvent?
    ) -> Bool {
        guard
            let overlayViewController,
            overlayViewController.isViewLoaded
        else {
            return true
        }

        let overlayViewFrame = overlayViewController.view.frame
        let touchPoint = view.convert(point, from: passthroughView)

        // Tap gesture recognizer should only be triggered if the touch location is within the collapsed overlay view
        let shouldRecognizeTouch = overlayViewFrame.contains(touchPoint) && isCollapsedState

        return !shouldRecognizeTouch
    }
}

// MARK: - OverlayContentContainerAppLifecycleHelperDelegate protocol conformance

extension OverlayContentContainerViewController: OverlayContentContainerAppLifecycleHelperDelegate {
    func currentProgress(for appLifecycleHelper: OverlayContentContainerAppLifecycleHelper) -> CGFloat {
        return progress
    }

    func appLifecycleHelperDidTriggerExpand(_ appLifecycleHelper: OverlayContentContainerAppLifecycleHelper) {
        expand()
    }

    func appLifecycleHelperDidTriggerCollapse(_ appLifecycleHelper: OverlayContentContainerAppLifecycleHelper) {
        collapse()
    }
}

// MARK: - Auxiliary types

private extension OverlayContentContainerViewController {
    private enum VerticalDirection {
        case up
        case down
    }
}

// MARK: - Constants

private extension OverlayContentContainerViewController {
    enum Constants {
        static let minContentViewScale = 0.95
        static let maxContentViewScale = 1.0
        static let minBackgroundShadowViewAlpha = 0.0
        static let maxBackgroundShadowViewAlpha = 0.5
        static let cornerRadius = 24.0
        static let defaultAnimationDuration = 0.3
        static let contentViewTranslationCoefficient = 0.5
        static let minAdjustedContentOffsetToLockScrollView = 10.0
    }
}
