//
//  ListDataLoader.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

protocol ListDataLoaderDelegate: AnyObject {
    func filter(_ model: CoinModel) -> CoinModel?
}

class ListDataLoader {
    // MARK: Output
    
    @Published var items: [CoinModel] = []
    
    // Tells if all records have been loaded. (Used to hide/show activity spinner)
    private(set) var canFetchMore = true
    
    weak var delegate: ListDataLoaderDelegate? = nil
    
    // MARK: Input

    private let isTestnet: Bool
    private let coinsService: CoinsService
    
    // MARK: Private
    
    // Tracks last page loaded. Used to load next page (current + 1)
    private var currentPage = 0
    
    // Limit of records per page. (Only if backend supports, it usually does)
    private let perPage = 50
    
    private var cancellable: AnyCancellable?
    private var currentRequests: [String: AnyCancellable?] = [:]
    
    private var cached: [CoinModel] = []
    private var cachedSearch: [String: [CoinModel]] = [:]
    private var lastSearchText = ""
    
    init(isTestnet: Bool, coinsService: CoinsService) {
        self.isTestnet = isTestnet
        self.coinsService = coinsService
    }
    
    func reset(_ searchText: String) {
        self.canFetchMore = true
        self.items = []
        self.currentPage = 0
        self.lastSearchText = searchText
        self.cachedSearch = [:]
    }
    
    func fetch(_ searchText: String) {
        cancellable = nil
        
        if lastSearchText != searchText {
            reset(searchText)
        }
     
        cancellable = loadItems(searchText)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                guard let self = self else { return }
                
                self.currentPage += 1
                self.items.append(contentsOf: items)
                // If count of data received is less than perPage value then it is last page.
                if items.count < self.perPage {
                    self.canFetchMore = false
                }
        }
    }
}

// MARK: Private

private extension ListDataLoader {
    func loadItems(_ searchText: String) -> AnyPublisher<[CoinModel], Never> {
        // If testnet then use local coins from testnet_tokens.json file
        if isTestnet {
            return loadTestnetItems(searchText)
        }
    
        return loadCoinsItems(searchText)
    }
    
    func loadTestnetItems(_ searchText: String) -> AnyPublisher<[CoinModel], Never> {
        let searchText = searchText.lowercased()
        let itemsPublisher: AnyPublisher<[CoinModel], Never>
        
        if cached.isEmpty {
            itemsPublisher = loadCoinsFromLocalJsonPublisher()
        } else {
            itemsPublisher = Just(cached).eraseToAnyPublisher()
        }
        
        return itemsPublisher
            .map { [weak self] models -> [CoinModel] in
                guard let self = self else { return [] }
                
                if searchText.isEmpty { return models }
                
                if let cachedSearch = self.cachedSearch[searchText] {
                    return cachedSearch
                }
             
                let foundItems = models.filter {
                    "\($0.name) \($0.symbol)".lowercased().contains(searchText)
                }
                
                self.cachedSearch[searchText] = foundItems
                
                return foundItems
            }
            .map { [weak self] models -> [CoinModel] in
                self?.getPage(for: models) ?? []
            }
            .eraseToAnyPublisher()
    }
    
    func loadCoinsItems(_ searchText: String) -> AnyPublisher<[CoinModel], Never> {
        let requestModel = CoinsListRequestModel(
            searchText: searchText,
            limit: perPage,
            offset: items.count
        )
        
        return coinsService.loadCoins(requestModel: requestModel)
            .map { [weak self] models -> [CoinModel] in
                models.compactMap { self?.delegate?.filter($0) }
            }
            .replaceError(with: [])
            .eraseToAnyPublisher()
    }
    
    func loadCoinsFromLocalJsonPublisher() -> AnyPublisher<[CoinModel], Never> {
        SupportedTokenItems().loadCoins()
            .map { [weak self] models -> [CoinModel] in
                models.compactMap { self?.delegate?.filter($0) }
            }
            .handleEvents(receiveOutput: { [weak self] output in
                self?.cached = output
            })
            .replaceError(with: [])
            .eraseToAnyPublisher()
    }
    
    func getPage(for items: [CoinModel]) -> [CoinModel] {
        Array(items.dropFirst(currentPage * perPage).prefix(perPage))
    }
}
