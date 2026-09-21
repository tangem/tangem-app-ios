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

@MainActor
public final class SlidePlayerViewModel: ObservableObject, Identifiable {
    // MARK: - Identity

    public nonisolated var id: String { slide.id }
    public nonisolated let slide: SlideV2

    // MARK: - What the slide view renders

    @Published public private(set) var state: State = .preparing
    /// Parsed lottie asset; the slide view renders whatever frame the progress points at.
    @Published private(set) var animation: LottieAnimation?
    public let progress = SlideProgress()
    public private(set) var player: AVPlayer?

    // MARK: - Derived state

    public var watchedMs: Int { engine.watchedMs }
    public var didComplete: Bool { state == .completed }

    /// `state` is the single lifecycle machine; a slide is driving playback exactly while it
    /// shows content. `engine.isPaused` is orthogonal.
    private var isActive: Bool { state == .playing || state == .buffering }

    // MARK: - Callbacks

    var onCompleted: (() -> Void)?

    // MARK: - Dependencies

    private let clock: ProgressClock
    private let animationLoader: StoryAnimationLoading
    /// Patterns handed to the engine run on their own, so every path that pauses, rewinds or tears
    /// the slide down has to stop them.
    private let hapticPlayer: (any StoryHapticPlaying)?

    // MARK: - Playback machinery

    private let engine = Engine()
    private let stallGuard: SlideStallGuard

    // MARK: - Work in flight

    private var tickerToken: AnyCancellable?
    private var animationTask: Task<Void, Never>?

    // MARK: - AVPlayer observers

    private var timeObserver: Any?
    private var statusObservation: NSKeyValueObservation?
    private var prerollObservation: NSKeyValueObservation?
    private var endObserver: NSObjectProtocol?

    init(
        slide: SlideV2,
        clock: ProgressClock = RealProgressClock(),
        animationLoader: StoryAnimationLoading = StoryAnimationLoader(),
        hapticPlayer: (any StoryHapticPlaying)? = nil,
        stallTimeout: TimeInterval = Constants.stallTimeout
    ) {
        self.slide = slide
        self.clock = clock
        self.animationLoader = animationLoader
        self.hapticPlayer = hapticPlayer
        stallGuard = SlideStallGuard(timeout: stallTimeout, maxBufferingWindows: Constants.maxBufferingWindows)
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
        guard !engine.hasPrepared else { return }
        engine.hasPrepared = true
        resetProgress()
        state = .preparing
        engine.playbackDurationMs = Double(slide.asset.durationMs)
        engine.loadHapticClusters(from: slide.hapticAtMs)

        if engine.hasHaptics {
            hapticPlayer?.prepare()
        }

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
        engine.isPaused = true
        player?.pause()
        hapticPlayer?.stopPlayback()
    }

    func resume() {
        guard engine.isPaused else { return }
        engine.isPaused = false
        if engine.didReachEndWhilePaused {
            engine.didReachEndWhilePaused = false
            complete()
            return
        }
        // A pending rewind seek finishes with resumeVideoPlayback(); playing here would start
        // from the stale pre-seek position.
        guard !engine.isSeekingToStart else { return }
        player?.play()
    }

    /// Stops and rewinds while keeping the asset prepared (slide left the active position).
    /// Pause doesn't survive the departure — otherwise the slide comes back frozen.
    public func rewindToPrepared() {
        stallGuard.cancel()
        tickerToken?.cancel()
        tickerToken = nil
        engine.isPaused = false
        engine.isSeekingToStart = false
        resetProgress()
        state = .preparing

        if let player {
            player.pause()
            engine.isSeekingToStart = true
            player.seek(to: .zero) { [weak self] _ in
                Task { @MainActor in
                    self?.engine.isSeekingToStart = false
                }
            }
        }

        hapticPlayer?.stopPlayback()
    }

    public func restart() {
        engine.isPaused = false

        // Seek instead of recreating the AVPlayer — a fresh player flashes black on the layer.
        if slide.asset.type == .video, engine.hasPrepared, let player {
            hapticPlayer?.stopPlayback()
            resetProgress()
            state = .playing
            // Armed across the seek too: a wedged seek must skip the slide, not freeze the story.
            armStallGuard()
            player.pause()
            // Resume only after the seek lands — the periodic observer would otherwise tick with
            // the pre-seek time and re-inflate progress/watchedMs right after the reset.
            engine.isSeekingToStart = true
            player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
                Task { @MainActor in
                    guard let self else { return }
                    self.engine.isSeekingToStart = false
                    guard self.state == .playing else { return }
                    self.resumeVideoPlayback()
                }
            }
            return
        }

        teardown()
        engine.hasPrepared = false
        state = .preparing
        play()
    }

    public func teardown() {
        animationTask?.cancel()
        animationTask = nil
        stallGuard.cancel()
        tickerToken?.cancel()
        tickerToken = nil
        engine.isSeekingToStart = false
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
        hapticPlayer?.stopPlayback()

        // A slide left looking active could never start again: `play()` would take its `!isActive`
        // early return. `.playing` is deliberately left alone — a torn-down story is mid-dismissal,
        // and swapping a spinner in over the last frame would flash.
        if state == .buffering {
            state = .preparing
        }
    }

    private func resetProgress() {
        engine.reset()
        progress.value = 0
    }

    // MARK: - Ticker path

    private func beginTicker() {
        state = .playing
        tickerToken = clock.start(interval: Constants.tick) { [weak self] delta in
            self?.tick(delta: delta)
        }
    }

    private func tick(delta: TimeInterval) {
        guard state == .playing, !engine.isPaused else { return }
        engine.advance(by: delta)
        progress.value = engine.progressValue
        fireHaptics(atMs: engine.elapsedMs)
        if engine.didReachDuration { complete() }
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
    /// poster, the same way a video without a player does. Waiting is `.buffering`, so the stall
    /// guard bounds it and a load that never lands can't leave the story sitting on a spinner.
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
        armStallGuard()
    }

    // MARK: - Video path

    private func setupVideoPlayer(url: URL) {
        StoryAudioSession.activateAmbientOnce()

        let player = makePlayer(url: url)
        self.player = player

        if url.isFileURL {
            observePrerollReadiness(of: player)
        }
        observePlayhead(of: player)
        observeStalling(of: player)
        observeEnd(of: player)
    }

    private func makePlayer(url: URL) -> AVPlayer {
        let player = AVPlayer(url: url)
        player.isMuted = true
        player.actionAtItemEnd = .pause
        // Instant start for local files; network URLs keep the default — without auto-waiting
        // a drained buffer stops the player for good and `.buffering` is never reported.
        player.automaticallyWaitsToMinimizeStalling = !url.isFileURL
        return player
    }

    /// Preroll requires `.readyToPlay` (defer to the KVO) and auto-waiting off — with auto-waiting
    /// on, AVPlayer rejects it or raises. An already playing slide decodes frames itself, so
    /// prerolling it would be wasted work.
    private func observePrerollReadiness(of player: AVPlayer) {
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

    /// The observer fires on the requested `.main` queue, so main-actor access is synchronous —
    /// no Task hop that would allocate per tick and reorder against user input.
    private func observePlayhead(of player: AVPlayer) {
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
                self.engine.playbackDurationMs = item.duration.seconds * 1000
                let curMs = time.seconds * 1000
                self.engine.moveHead(toMs: curMs)
                self.progress.value = self.engine.progressValue
                self.fireHaptics(atMs: curMs)
            }
        }
    }

    private func observeStalling(of player: AVPlayer) {
        statusObservation = player.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
            Task { @MainActor in
                guard let self, self.isActive else { return }
                if player.timeControlStatus == .waitingToPlayAtSpecifiedRate, self.state == .playing {
                    self.state = .buffering
                }
            }
        }
    }

    private func observeEnd(of player: AVPlayer) {
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, self.isActive else { return }
                // Completing under an active pause would switch slides beneath the user's
                // finger; remember the end and let resume() finish the slide.
                if self.engine.isPaused {
                    self.engine.didReachEndWhilePaused = true
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
        armStallGuard()
        if !engine.isPaused {
            player?.play()
        }
    }

    // MARK: - Stall guard

    private func armStallGuard() {
        stallGuard.arm(
            probe: { [weak self] in self?.stallProbe() ?? .finished },
            onStall: { [weak self] in self?.complete() }
        )
    }

    private func stallProbe() -> SlideStallGuard.Probe {
        guard state != .completed else { return .finished }
        guard isActive, !engine.isPaused else { return .idle }
        guard state != .buffering else { return .buffering }
        return .progressing(watchedMs: engine.watchedMs)
    }

    // MARK: - Completion

    private func complete() {
        guard state != .completed else { return }
        progress.value = 1
        state = .completed
        tickerToken?.cancel()
        tickerToken = nil
        stallGuard.cancel()
        onCompleted?()
    }

    // MARK: - Haptics

    /// A rewind seek keeps reporting the pre-seek position while it runs, with the fired set
    /// already cleared — without the latch every cluster would fire in that one tick.
    private func fireHaptics(atMs: Double) {
        guard !engine.isPaused, !engine.isSeekingToStart else { return }

        for cluster in engine.clustersToFire(atMs: atMs) {
            hapticPlayer?.play(cluster)
        }
    }

    private enum Constants {
        static let tick: Double = 1.0 / 60.0
        static let stallTimeout: Double = 3.0
        static let maxBufferingWindows = 3
    }
}
