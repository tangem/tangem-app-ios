//
//  PolymarketFeedLiveGamesTracker.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemPolymarket

@MainActor
final class PolymarketFeedLiveGamesTracker {
    let updates: AsyncStream<Update>

    private let reader: PolymarketLiveTopicsReader<String, PolymarketLiveGame>
    private let delayProvider: any PollDelayProvider
    private let updatesContinuation: AsyncStream<Update>.Continuation

    private var readerTask: Task<Void, Never>?
    private var lastSeenGames: [String: PolymarketLiveGame] = [:]
    private var silenceTasks: [String: Task<Void, Never>] = [:]

    var trackedGameIds: Set<String> {
        reader.trackedTopics
    }

    init(
        games: @escaping @Sendable (Set<String>) async -> AsyncStream<PolymarketLiveGame>,
        statusChanges: @escaping @Sendable () async -> AsyncStream<PolymarketWebSocketConnectionStatus>,
        delayProvider: any PollDelayProvider = TaskSleepPollDelayProvider()
    ) {
        reader = PolymarketLiveTopicsReader(values: games, statusChanges: statusChanges)
        self.delayProvider = delayProvider
        (updates, updatesContinuation) = AsyncStream.makeStream(of: Update.self)

        readerTask = Task { [weak self, readerUpdates = reader.updates] in
            for await update in readerUpdates {
                self?.handle(update)
            }
        }
    }

    convenience init(liveGames: PolymarketLiveGames) {
        self.init(
            games: { gameIds in await liveGames.games(for: gameIds) },
            statusChanges: { await liveGames.statusChanges() }
        )
    }

    deinit {
        readerTask?.cancel()
        silenceTasks.values.forEach { $0.cancel() }
        updatesContinuation.finish()
    }

    func update(events: [PolymarketEvent]) {
        reader.track(Set(events.compactMap(\.game?.gameId)))
        forgetGames { !trackedGameIds.contains($0) }
    }

    func pause() {
        reader.pause()
        forgetGames { _ in true }
    }

    func resume() {
        reader.resume()
    }
}

// MARK: - Update

extension PolymarketFeedLiveGamesTracker {
    enum Update: Sendable {
        case game(PolymarketLiveGame)
        case silent(gameId: String)
        case reconnected
    }
}

// MARK: - Private

private extension PolymarketFeedLiveGamesTracker {
    func handle(_ update: PolymarketLiveTopicsReader<String, PolymarketLiveGame>.Update) {
        switch update {
        case .value(let game):
            receive(game)
        case .connectionLost:
            break
        case .reconnected:
            updatesContinuation.yield(.reconnected)
        }
    }

    func receive(_ game: PolymarketLiveGame) {
        guard trackedGameIds.contains(game.gameId) else {
            return
        }

        restartSilenceTimer(for: game)

        guard lastSeenGames[game.gameId] != game else {
            return
        }

        lastSeenGames[game.gameId] = game
        updatesContinuation.yield(.game(game))
    }

    func restartSilenceTimer(for game: PolymarketLiveGame) {
        silenceTasks[game.gameId]?.cancel()
        silenceTasks[game.gameId] = nil

        guard !game.hasEnded else {
            return
        }

        silenceTasks[game.gameId] = Task { [weak self, delayProvider, gameId = game.gameId] in
            do {
                try await delayProvider.wait(for: Constants.silenceTimeout)
            } catch {
                return
            }

            guard !Task.isCancelled else {
                return
            }

            self?.gameWentSilent(gameId)
        }
    }

    func gameWentSilent(_ gameId: String) {
        silenceTasks[gameId] = nil
        updatesContinuation.yield(.silent(gameId: gameId))
    }

    func forgetGames(where shouldForget: (String) -> Bool) {
        for gameId in Set(lastSeenGames.keys).union(silenceTasks.keys) where shouldForget(gameId) {
            silenceTasks[gameId]?.cancel()
            silenceTasks[gameId] = nil
            lastSeenGames[gameId] = nil
        }
    }
}

// MARK: - Constants

private enum Constants {
    static let silenceTimeout: TimeInterval = 10 * 60
}
