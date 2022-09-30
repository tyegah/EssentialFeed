//
//  LocalFeedLoader.swift
//  EssentialFeed
//
//  Created by Ty Septiani on 26/09/22.
//

import Foundation


private class FeedCachePolicy {
    private let currentDate: () -> Date
    private let calendar = Calendar(identifier: .gregorian)
    
    public init(currentDate: @escaping () -> Date) {
        self.currentDate = currentDate
    }
    
    //** LocalFeedLoader as UseCase should encapsulate application-specific logic only and communicate with models to perform business logic
    //** These two methods (maxCacheAgeInDays & validate timeStamp) are considered Rules & Policies or validation logic
    //** They're better suited in the Domain Model that is application agnostic (so it can be reused accross applications)
    //** This is why we create this FeedCachePolicy class
    
    private var maxCacheAgeInDays:Int {
        return 7
    }
    
    func validate(_ timestamp: Date) -> Bool {
        guard let maxCacheAge = calendar.date(byAdding: .day, value: maxCacheAgeInDays, to: timestamp) else {
            return false
        }
        return currentDate() < maxCacheAge
    }
}

public final class LocalFeedLoader {
    private let store:FeedStore
    private let currentDate: () -> Date
    private let cachePolicy: FeedCachePolicy
    
    // This currentDate is created with closure because it is not a pure function, which means that
    // Everytime init() is called, it creates a different value
    // So instead of letting the UseCase produce the current date via the impure function (Date.init()) directly
    // We move this responsibility to a collabolator (which is the closure in this case), and inject it as a dependency
    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
        self.cachePolicy = FeedCachePolicy(currentDate: currentDate)
    }
}
    
extension LocalFeedLoader {
    public typealias SaveResult = Error?
    
    public func save(_ feed: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        store.deleteCachedFeed { [weak self] error in
            guard let self = self else { return }
            
            if let cacheDeletionError = error {
                completion(cacheDeletionError)
            }
            else {
                self.cache(feed, with: completion)
            }
        }
    }
    
    private func cache(_ feed:[FeedImage], with completion: @escaping (Error?) -> Void) {
        store.insert(feed.toLocal(), timeStamp: currentDate()) {[weak self] error in
            guard self != nil else { return }
            completion(error)
        }
    }
}

extension LocalFeedLoader: FeedLoader {
    public typealias LoadResult = LoadFeedResult
    
    public func load(completion: @escaping (LoadResult) -> Void) {
        store.retrieve { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case let .failure(error):
                completion(.failure(error))
            case let .found(feed, timestamp) where self.cachePolicy.validate(timestamp):
                completion(.success(feed.toModels()))
            case .found, .empty:
                completion(.success([]))
            }
        }
    }
}
    
extension LocalFeedLoader {
    public func validateCache() {
        store.retrieve { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .failure:
                self.store.deleteCachedFeed { _ in }
            case let .found(_, timestamp) where !self.cachePolicy.validate(timestamp):
                self.store.deleteCachedFeed { _ in }
            case .empty, .found: break
            }
        }
    }
}
    

private extension Array where Element == FeedImage {
    func toLocal() -> [LocalFeedImage] {
        return self.map { LocalFeedImage(id: $0.id,
                                         description: $0.description,
                                         location: $0.location,
                                         url: $0.url) }
    }
}

private extension Array where Element == LocalFeedImage {
    func toModels() -> [FeedImage] {
        return self.map { FeedImage(id: $0.id,
                                    description: $0.description,
                                    location: $0.location,
                                    url: $0.url) }
    }
}
