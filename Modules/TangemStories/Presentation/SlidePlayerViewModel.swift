//
//  SlidePlayerViewModel.swift
//  TangemStories
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import AVFoundation
import Lottie
import UIKit

/// Playback progress ticks at 60 Hz; it lives apart from `SlidePlayerViewModel` so per-tick
/// updates invalidate only the progress bar, not every view observing the slide.
@MainActor
public final class SlideProgress: ObservableObject {
    @Published public fileprivate(set) var value: Double = 0
}

@MainActor
public final class SlidePlayerViewModel: ObservableObject, Identifiable {
    public enum State: Equatable {
        case preparing
        case playing
        case buffering
        case completed
    }

    public nonisolated var id: String { slide.id }
    public nonisolated let slide: SlideV2

    @Published public private(set) var state: State = .preparing

    public let progress = SlideProgress()

    public private(set) var watchedMs: Int = 0
    public var didComplete: Bool { state == .completed }

    var onCompleted: (() -> Void)?
    public var hapticsEnabled = true

    // MARK: - Private properties

    public private(set) var player: AVPlayer?
    /// Parsed lottie asset; the slide view renders whatever frame the progress points at.
    @Published private(set) var animation: LottieAnimation?
    private var animationTask: Task<Void, Never>?
    private var timeObserver: Any?
    private var statusObservation: NSKeyValueObservation?
    private var prerollObservation: NSKeyValueObservation?
    private var endObserver: NSObjectProtocol?

    private let clock: ProgressClock
    private let animationLoader: StoryAnimationLoading
    private let stallTimeout: TimeInterval
    private var tickerToken: AnyCancellable?
    private var stallGuardTask: Task<Void, Never>?
    private var elapsedMs: Double = 0
    /// Drives progress only; for video the real media length takes over. Analytics must keep
    /// reporting the contract value from `slide.asset.durationMs`.
    private var playbackDurationMs: Double = 0

    /// The one bit `state` can't express: idle and prepared slides both render as `.preparing`,
    /// but only an unprepared one may open the asset (a second prepare would leak an AVPlayer).
    private var hasPrepared = false
    private var isPaused = false
    // Transition latches; only meaningful while the slide is active.
    private var isSeekingToStart = false
    private var didReachEndWhilePaused = false
    private var firedHaptics = Set<Int>()

    /// `state` is the single lifecycle machine; a slide is driving playback exactly while it
    /// shows content. `isPaused` is orthogonal.
    private var isActive: Bool { state == .playing || state == .buffering }

    init(
        slide: SlideV2,
        clock: ProgressClock = RealProgressClock(),
        animationLoader: StoryAnimationLoading = StoryAnimationLoader(),
        stallTimeout: TimeInterval = Constants.stallTimeout
    ) {
        self.slide = slide
        self.clock = clock
        self.animationLoader = animationLoader
        self.stallTimeout = stallTimeout
    }

    deinit {
        // AVPlayer.removeTimeObserver requires manual invocation; KVO + notification-token
        // observers self-invalidate on dealloc. VM is expected to be released on main.
        if let timeObserver, let player {
            player.removeTimeObserver(timeObserver)
        }
    }

    // MARK: - Lifecycle

    /// Opens the asset without starting playback so neighbours can be preloaded.
    public func prepare() {
        guard !hasPrepared else { return }
        hasPrepared = true
        resetProgress()
        state = .preparing
        playbackDurationMs = Double(slide.asset.durationMs)

        switch slide.asset.type {
        case .video:
            if let url = slide.asset.url {
                setupVideoPlayer(url: url)
            }
        case .lottie:
            loadAnimation()
        case .image:
            break
        }
    }

    public func play() {
        prepare()
        guard !isActive else { return }

        switch slide.asset.type {
        case .image:
            beginTicker()
        case .lottie:
            startAnimationPlayback()
        case .video:
            startVideoPlayback()
        }
    }

    func pause() {
        isPaused = true
        player?.pause()
    }

    func resume() {
        guard isPaused else { return }
        isPaused = false
        if didReachEndWhilePaused {
            didReachEndWhilePaused = false
            complete()
            return
        }
        // A pending rewind seek finishes with resumeVideoPlayback(); playing here would start
        // from the stale pre-seek position.
        guard !isSeekingToStart else { return }
        player?.play()
    }

    /// Stops and rewinds while keeping the asset prepared (slide left the active position).
    /// Pause doesn't survive the departure — otherwise the slide comes back frozen.
    public func rewindToPrepared() {
        stallGuardTask?.cancel()
        stallGuardTask = nil
        tickerToken?.cancel()
        tickerToken = nil
        isPaused = false
        isSeekingToStart = false
        resetProgress()
        state = .preparing
        player?.pause()
        player?.seek(to: .zero)
    }

    public func restart() {
        isPaused = false

        // Seek instead of recreating the AVPlayer — a fresh player flashes black on the layer.
        if slide.asset.type == .video, hasPrepared, let player {
            resetProgress()
            state = .playing
            // Armed across the seek too: a wedged seek must skip the slide, not freeze the story.
            scheduleStallGuard()
            player.pause()
            // Resume only after the seek lands — the periodic observer would otherwise tick with
            // the pre-seek time and re-inflate progress/watchedMs right after the reset.
            isSeekingToStart = true
            player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
                Task { @MainActor in
                    guard let self else { return }
                    self.isSeekingToStart = false
                    guard self.state == .playing else { return }
                    self.resumeVideoPlayback()
                }
            }
            return
        }

        teardown()
        hasPrepared = false
        state = .preparing
        play()
    }

    public func teardown() {
        animationTask?.cancel()
        animationTask = nil
        stallGuardTask?.cancel()
        stallGuardTask = nil
        tickerToken?.cancel()
        tickerToken = nil
        isSeekingToStart = false
        if let timeObserver {
            player?.removeTimeObserver(timeObserver)
        }
        timeObserver = nil
        statusObservation?.invalidate()
        statusObservation = nil
        prerollObservation?.invalidate()
        prerollObservation = nil
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        endObserver = nil
        player?.pause()

        // Nothing is running any more, so the slide must not keep looking active: `play()` would
        // take its `!isActive` early return and the slide could never start again. `.playing` is
        // deliberately left alone — a torn-down story is mid-dismissal, and swapping a spinner in
        // over the last frame would flash.
        if state == .buffering {
            state = .preparing
        }
    }

    private func resetProgress() {
        elapsedMs = 0
        watchedMs = 0
        progress.value = 0
        didReachEndWhilePaused = false
        firedHaptics.removeAll()
    }

    // MARK: - Ticker path

    private func beginTicker() {
        state = .playing
        tickerToken = clock.start(interval: Constants.tick) { [weak self] delta in
            self?.tick(delta: delta)
        }
    }

    private func tick(delta: TimeInterval) {
        guard state == .playing, !isPaused else { return }
        elapsedMs += delta * 1000
        watchedMs = Int(elapsedMs)
        progress.value = min(elapsedMs / max(playbackDurationMs, 1), 1)
        fireHapticsIfNeeded(atMs: elapsedMs)
        if elapsedMs >= playbackDurationMs { complete() }
    }

    // MARK: - Animation path

    /// Loaded during `prepare()`, so a window neighbour is ready before it becomes visible —
    /// the same contract the video path gets from `setupVideoPlayer`.
    private func loadAnimation() {
        guard animation == nil, animationTask == nil, let url = slide.asset.url else { return }

        animationTask = Task { [weak self, animationLoader] in
            let loaded = await animationLoader.animation(at: url)
            guard !Task.isCancelled, let self else { return }
            animationTask = nil
            animation = loaded

            // Anything but `.buffering` means nobody is waiting on this load: the slide is a
            // window neighbour, or it has already left the active position.
            guard state == .buffering else { return }

            if animation == nil {
                complete()
            } else {
                beginTicker()
            }
        }
    }

    /// An asset that never arrives skips the slide instead of running the progress bar over a
    /// poster, the same way a video without a player does. Waiting is `.buffering` — the state
    /// already means "active but no content yet", so the stall guard bounds this wait too and a
    /// load that never lands can't leave the story sitting on a spinner. It also inherits
    /// `SlideStage`'s spinner delay, so a load that resolves inside it shows the poster rather
    /// than a spinner flash — the trade the video path already makes.
    private func startAnimationPlayback() {
        if animation != nil {
            beginTicker()
            return
        }

        loadAnimation()
        guard animationTask != nil else {
            complete()
            return
        }

        state = .buffering
        scheduleStallGuard()
    }

    // MARK: - Video path

    private func setupVideoPlayer(url: URL) {
        Self.activateAmbientAudioSessionOnce()
        let player = AVPlayer(url: url)
        player.isMuted = true
        player.actionAtItemEnd = .pause
        // Instant start for local files; network URLs keep the default — without auto-waiting
        // a drained buffer stops the player for good and `.buffering` is never reported.
        player.automaticallyWaitsToMinimizeStalling = !url.isFileURL
        self.player = player

        // Preroll requires `.readyToPlay` (defer to the KVO) and auto-waiting off — with
        // auto-waiting on, AVPlayer rejects it or raises. An already playing slide decodes
        // frames itself, so prerolling it would be wasted work.
        if url.isFileURL {
            prerollObservation = player.observe(\.status, options: [.initial, .new]) { [weak self] player, _ in
                guard player.status == .readyToPlay else { return }
                Task { @MainActor in
                    guard let self, self.player === player else { return }
                    self.prerollObservation?.invalidate()
                    self.prerollObservation = nil
                    if !self.isActive {
                        player.preroll(atRate: 1)
                    }
                }
            }
        }

        // The observer fires on the requested `.main` queue, so main-actor access is synchronous —
        // no Task hop that would allocate per tick and reorder against user input.
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: Constants.tick, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            MainActor.assumeIsolated {
                guard let self, self.isActive,
                      let player = self.player,
                      let item = player.currentItem,
                      item.duration.isNumeric else { return }
                if self.state == .buffering { self.state = .playing }
                self.playbackDurationMs = item.duration.seconds * 1000
                let curMs = time.seconds * 1000
                self.watchedMs = max(self.watchedMs, Int(curMs))
                self.progress.value = min(curMs / max(self.playbackDurationMs, 1), 1)
                self.fireHapticsIfNeeded(atMs: curMs)
            }
        }

        statusObservation = player.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
            Task { @MainActor in
                guard let self, self.isActive else { return }
                if player.timeControlStatus == .waitingToPlayAtSpecifiedRate, self.state == .playing {
                    self.state = .buffering
                }
            }
        }

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, self.isActive else { return }
                // Completing under an active pause would switch slides beneath the user's
                // finger; remember the end and let resume() finish the slide.
                if self.isPaused {
                    self.didReachEndWhilePaused = true
                    return
                }
                self.complete()
            }
        }
    }

    private func startVideoPlayback() {
        guard player != nil else {
            complete()
            return
        }
        resumeVideoPlayback()
    }

    private func resumeVideoPlayback() {
        state = .playing
        scheduleStallGuard()
        if !isPaused {
            player?.play()
        }
    }

    // MARK: - Stall guard

    /// Skips the slide when playback makes no progress across a full timeout window, at start or
    /// mid-play. Pause windows re-arm the watchdog; `teardown()` cancels it. Buffering — a stalled
    /// stream or a pending animation load — gets a longer, but bounded, grace: an asset that never
    /// arrives must not leave the user on an infinite spinner.
    private func scheduleStallGuard() {
        stallGuardTask?.cancel()
        stallGuardTask = Task { [weak self, stallTimeout] in
            // `nil` marks a paused window: skip one comparison after resume.
            var lastWatchedMs: Int? = 0
            var bufferingWindows = 0
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(stallTimeout * 1_000_000_000))
                guard !Task.isCancelled, let self, state != .completed else { return }
                guard isActive, !isPaused else {
                    lastWatchedMs = nil
                    bufferingWindows = 0
                    continue
                }
                if state == .buffering {
                    bufferingWindows += 1
                    if bufferingWindows >= Constants.maxBufferingWindows {
                        complete()
                        return
                    }
                    lastWatchedMs = nil
                    continue
                }
                bufferingWindows = 0
                if let last = lastWatchedMs, last == watchedMs {
                    complete()
                    return
                }
                lastWatchedMs = watchedMs
            }
        }
    }

    // MARK: - Completion

    private func complete() {
        guard state != .completed else { return }
        progress.value = 1
        state = .completed
        tickerToken?.cancel()
        tickerToken = nil
        stallGuardTask?.cancel()
        stallGuardTask = nil
        onCompleted?()
    }

    // MARK: - Haptics

    private func fireHapticsIfNeeded(atMs: Double) {
        guard !isPaused, hapticsEnabled else { return }
        for mark in slide.hapticAtMs where !firedHaptics.contains(mark) {
            if atMs >= Double(mark) {
                firedHaptics.insert(mark)
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
        }
    }

    // MARK: - Audio session

    private static var ambientConfigured = false

    private static func activateAmbientAudioSessionOnce() {
        guard !ambientConfigured else { return }
        ambientConfigured = true
        // `.ambient` mixes with other audio so the user's music is never interrupted.
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
    }

    private enum Constants {
        static let tick: Double = 1.0 / 60.0
        static let stallTimeout: Double = 3.0
        static let maxBufferingWindows = 3
    }
}
