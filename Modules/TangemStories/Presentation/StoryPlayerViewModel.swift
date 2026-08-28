//
//  StoryPlayerViewModel.swift
//  TangemStories
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import UIKit

@MainActor
public final class StoryPlayerViewModel: ObservableObject {
    public let story: StoryV2

    @Published public private(set) var currentIndex: Int = 0
    @Published public private(set) var current: SlidePlayerViewModel
    /// Window of prepared slides in slide order; the view keeps them all mounted.
    @Published public private(set) var preparedSlides: [SlidePlayerViewModel] = []

    private let onFinished: (_ exitReason: StoryExitReason, _ action: StoryActionV2?) -> Void

    /// Prepared slides kept around the active one: [i-1, i, i+1].
    private var window: [Int: SlidePlayerViewModel] = [:]

    private var hasStarted = false
    private var firstLoopDone = false
    private var pauseReasons: Set<PauseReason> = []
    private var visibleViews = 0
    private var lifecycleObservers: [NSObjectProtocol] = []
    private let effectiveEndBehavior: EndBehavior

    public init(
        story: StoryV2,
        onFinished: @escaping (_ exitReason: StoryExitReason, _ action: StoryActionV2?) -> Void
    ) {
        precondition(!story.slides.isEmpty, "StoryPlayerViewModel requires a story with at least one slide")
        self.story = story
        self.onFinished = onFinished
        effectiveEndBehavior = story.effectiveEndBehavior

        let first = SlidePlayerViewModel(slide: story.slides[0])
        window[0] = first
        current = first
        preparedSlides = [first]

        observeApplicationLifecycle()
    }

    deinit {
        for observer in lifecycleObservers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    /// The app runs the UIKit lifecycle, where SwiftUI's `\.scenePhase` never updates inside a
    /// hosting controller — background transitions must come from UIApplication directly.
    private func observeApplicationLifecycle() {
        let center = NotificationCenter.default
        lifecycleObservers = [
            center.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.setPaused(true, for: .background) }
            },
            center.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.setPaused(false, for: .background) }
            },
        ]
    }

    // MARK: - Lifecycle

    /// Kick off playback of the first slide. Idempotent — safe to call from view's `onAppear`.
    public func start() {
        guard !hasStarted else { return }
        hasStarted = true
        activate(index: 0)
    }

    // MARK: - Controls

    public func tapForward() {
        advanceOrFinish()
    }

    public func tapBackward() {
        if currentIndex > 0 {
            activate(index: currentIndex - 1)
        } else {
            current.restart()
            applyPauseState()
        }
    }

    /// Pause sources are independent (hold, background, cover) — playback resumes only
    /// when every reason that paused it has lifted.
    public enum PauseReason: Hashable {
        case hold
        case background
        case cover
    }

    public func setPaused(_ paused: Bool, for reason: PauseReason) {
        if paused {
            pauseReasons.insert(reason)
        } else {
            pauseReasons.remove(reason)
        }
        applyPauseState()
    }

    /// Reappearing rebuilds the pause set from live state: per-event bookkeeping goes stale
    /// while the view is out of the hierarchy (undelivered lifecycle / hold-release events).
    public func viewAppeared() {
        visibleViews += 1
        pauseReasons = UIApplication.shared.applicationState == .active ? [] : [.background]
        applyPauseState()
    }

    /// Balanced against `viewAppeared` so interleaved appear/disappear of two view instances
    /// sharing this model can't wedge a stale cover pause.
    public func viewDisappeared() {
        visibleViews = max(0, visibleViews - 1)
        if visibleViews == 0 {
            pauseReasons.insert(.cover)
            applyPauseState()
        }
    }

    private func applyPauseState() {
        if pauseReasons.isEmpty {
            current.resume()
        } else {
            current.pause()
        }
    }

    public func closeButtonTapped() { finalize(exitReason: .closeButton, action: nil) }
    public func swipeDown() { finalize(exitReason: .swipeDown, action: nil) }
    public func actionTapped(_ action: StoryActionV2) { finalize(exitReason: .action, action: action) }

    // MARK: - Navigation

    private func activate(index: Int) {
        currentIndex = index
        refreshWindow(around: index)

        let vm = window[index] ?? makePrepared(at: index)
        vm.hapticsEnabled = !firstLoopDone
        vm.onCompleted = { [weak self] in self?.advanceOrFinish() }
        current = vm

        // A completed slide can be re-activated in place (single-slide loop: refreshWindow never
        // rewinds the active index) — play() would no-op on it.
        if vm.didComplete {
            vm.restart()
        } else {
            vm.play()
        }

        // A handover can happen while a reason is held (e.g. end-of-video races a hold) —
        // the incoming slide must not escape the active pause.
        applyPauseState()
    }

    private func refreshWindow(around index: Int) {
        var wanted = Set([index - 1, index, index + 1].filter { story.slides.indices.contains($0) })
        // Only the forward wrap is reachable: tapBackward on the first slide restarts it.
        if effectiveEndBehavior == .loop, index == story.slides.count - 1 {
            wanted.insert(0)
        }

        // Mutating a dictionary during its own iteration is undefined in Swift — snapshot keys first.
        let stale = window.keys.filter { !wanted.contains($0) }
        for idx in stale {
            window[idx]?.teardown()
            window[idx] = nil
        }

        for idx in wanted where window[idx] == nil {
            _ = makePrepared(at: idx)
        }

        for (idx, vm) in window where idx != index {
            vm.rewindToPrepared()
        }

        preparedSlides = window.sorted { $0.key < $1.key }.map(\.value)
    }

    @discardableResult
    private func makePrepared(at index: Int) -> SlidePlayerViewModel {
        let vm = SlidePlayerViewModel(slide: story.slides[index])
        vm.prepare()
        window[index] = vm
        return vm
    }

    private func advanceOrFinish() {
        if currentIndex < story.slides.count - 1 {
            activate(index: currentIndex + 1)
        } else {
            handleEndReached()
        }
    }

    private func handleEndReached() {
        switch effectiveEndBehavior {
        case .finish:
            finalize(exitReason: .completed, action: story.actions.first)
        case .loop:
            firstLoopDone = true
            activate(index: 0)
        }
    }

    private func finalize(exitReason: StoryExitReason, action: StoryActionV2?) {
        teardownWindow()
        onFinished(exitReason, action)
    }

    private func teardownWindow() {
        for vm in window.values {
            vm.teardown()
        }
        window.removeAll()
    }
}

private extension StoryV2 {
    /// `.loop` is only safe when at least one slide surfaces an exit button; otherwise fall back
    /// to `.finish`. A slide's effective actions are `slide.actions ?? story.actions` — a slide
    /// that overrides with `[]` explicitly hides the story-level button on that slide.
    var effectiveEndBehavior: EndBehavior {
        guard endBehavior == .loop else { return endBehavior }
        let hasExitButton = slides.contains { !($0.actions ?? actions).isEmpty }
        return hasExitButton ? .loop : .finish
    }
}
