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
    func map(_ model: CurrencyModel) -> CurrencyViewModel
    func filter(_ model: CurrencyModel) -> CurrencyModel?
}

class ListDataLoader: ObservableObject {
    @Published var items = [CurrencyViewModel]()
    
    // Tells if all records have been loaded. (Used to hide/show activity spinner)
    private(set) var hasItems = true
    // Tracks last page loaded. Used to load next page (current + 1)
    private(set) var currentPage = 0
    // Limit of records per page. (Only if backend supports, it usually does)
    let perPage = 20
    
    let isTestnet: Bool
    
    weak var delegate: ListDataLoaderDelegate? = nil
    
    private var cancellable: AnyCancellable?
    private var cached: [CurrencyModel] = []
    private var cachedSearch: [String: [CurrencyModel]] = [:]
    private var lastSearchText = ""
    
    private var loadPublisher: AnyPublisher<[CurrencyModel], Never> {
        SupportedTokenItems().loadCurrencies(isTestnet: isTestnet)
            .map{[weak self] models -> [CurrencyModel] in
                models.compactMap { self?.delegate?.filter($0) }
            }
            .handleEvents(receiveOutput: {[weak self] output in
                self?.cached = output
            })
            .replaceError(with: [])
            .eraseToAnyPublisher()
    }
    
    private var cachePublisher: AnyPublisher<[CurrencyModel], Never> {
        Just(cached).eraseToAnyPublisher()
    }
    
    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }
    
    func fetch(_ searchText: String) {
        cancellable = nil
        
        if lastSearchText != searchText {
            self.hasItems = true
            self.items = []
            self.currentPage = 0
            self.lastSearchText = searchText
            self.cachedSearch = [:]
        }
     
        cancellable = loadItems(searchText)
            .map {[weak self] items -> [CurrencyViewModel] in
                return items.compactMap { self?.delegate?.map($0) }
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self = self else { return }
                
                self.currentPage += 1
                self.items.append(contentsOf: $0)
                // If count of data received is less than perPage value then it is last page.
                if $0.count < self.perPage {
                    self.hasItems = false
                }
        }
    }
    
    private func loadItems(_ searchText: String) -> AnyPublisher<[CurrencyModel], Never> {
        let searchText = searchText.lowercased()
        let itemsPublisher = cached.isEmpty ? loadPublisher : cachePublisher
        
        return itemsPublisher
            .map {[weak self] models -> [CurrencyModel] in
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
            .map {[weak self] models -> [CurrencyModel] in
                self?.getPage(for: models) ?? []
            }
            .eraseToAnyPublisher()
    }
    
    private func getPage(for items: [CurrencyModel]) -> [CurrencyModel] {
        Array(items.dropFirst(currentPage*perPage).prefix(perPage))
    }
}


