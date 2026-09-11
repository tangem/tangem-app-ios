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
import UIKit

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
    @Published public private(set) var progress: Double = 0

    public private(set) var watchedMs: Int = 0
    public var didComplete: Bool { state == .completed }

    var onCompleted: (() -> Void)?
    public var hapticsEnabled = true

    // MARK: - Private properties

    public private(set) var player: AVPlayer?
    private var timeObserver: Any?
    private var statusObservation: NSKeyValueObservation?
    private var endObserver: NSObjectProtocol?

    private let clock: ProgressClock
    private var tickerToken: AnyCancellable?
    private var stallGuardTask: Task<Void, Never>?
    private var elapsedMs: Double = 0
    private var durationMs: Double = 0

    private var hasPrepared = false
    private var isPlaying = false
    private var isPaused = false
    private var firedHaptics = Set<Int>()

    public init(slide: SlideV2, clock: ProgressClock = RealProgressClock()) {
        self.slide = slide
        self.clock = clock
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
        durationMs = Double(slide.asset.durationMs)

        if slide.asset.type == .video, let url = slide.asset.url {
            setupVideoPlayer(url: url)
        }
    }

    public func play() {
        prepare()
        guard !isPlaying else { return }
        isPlaying = true

        switch slide.asset.type {
        case .image, .lottie:
            beginTicker()
        case .video:
            startVideoPlayback()
        }
    }

    public func pause() {
        isPaused = true
        player?.pause()
    }

    public func resume() {
        guard isPaused else { return }
        isPaused = false
        player?.play()
    }

    /// Stops and rewinds while keeping the asset prepared (slide left the active position).
    public func rewindToPrepared() {
        tickerToken?.cancel()
        tickerToken = nil
        isPlaying = false
        resetProgress()
        state = .preparing
        player?.pause()
        player?.seek(to: .zero)
    }

    public func restart() {
        teardown()
        hasPrepared = false
        play()
    }

    public func teardown() {
        stallGuardTask?.cancel()
        stallGuardTask = nil
        tickerToken?.cancel()
        tickerToken = nil
        isPlaying = false
        if let timeObserver {
            player?.removeTimeObserver(timeObserver)
        }
        timeObserver = nil
        statusObservation?.invalidate()
        statusObservation = nil
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        endObserver = nil
        player?.pause()
    }

    private func resetProgress() {
        elapsedMs = 0
        watchedMs = 0
        progress = 0
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
        progress = min(elapsedMs / max(durationMs, 1), 1)
        fireHapticsIfNeeded(atMs: elapsedMs)
        if elapsedMs >= durationMs { complete() }
    }

    // MARK: - Video path

    private func setupVideoPlayer(url: URL) {
        Self.activateAmbientAudioSessionOnce()
        let player = AVPlayer(url: url)
        player.isMuted = true
        player.actionAtItemEnd = .pause
        self.player = player

        // The observer fires on the requested `.main` queue, so main-actor access is synchronous —
        // no Task hop that would allocate per tick and reorder against user input.
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: Constants.tick, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            MainActor.assumeIsolated {
                guard let self, self.isPlaying,
                      let player = self.player,
                      let item = player.currentItem,
                      item.duration.isNumeric else { return }
                if self.state == .buffering { self.state = .playing }
                self.durationMs = item.duration.seconds * 1000
                let curMs = time.seconds * 1000
                self.watchedMs = max(self.watchedMs, Int(curMs))
                self.progress = min(curMs / max(self.durationMs, 1), 1)
                self.fireHapticsIfNeeded(atMs: curMs)
            }
        }

        statusObservation = player.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
            Task { @MainActor in
                guard let self, self.isPlaying else { return }
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
                guard let self, self.isPlaying else { return }
                self.complete()
            }
        }
    }

    private func startVideoPlayback() {
        guard let player else {
            complete()
            return
        }
        state = .playing
        scheduleStallGuard()
        if !isPaused {
            player.play()
        }
    }

    /// No poster fallback: if playback hasn't progressed within the timeout, skip the slide instead
    /// of freezing the story. Cancelled by `teardown()` so a departing slide doesn't complete late.
    private func scheduleStallGuard() {
        stallGuardTask?.cancel()
        stallGuardTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(Constants.stallTimeout * 1_000_000_000))
            guard !Task.isCancelled, let self,
                  isPlaying, !self.isPaused,
                  state != .completed, progress == 0 else { return }
            complete()
        }
    }

    private func complete() {
        guard state != .completed else { return }
        progress = 1
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
                Self.fireHaptic()
            }
        }
    }

    private static func fireHaptic() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
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
    }
}
