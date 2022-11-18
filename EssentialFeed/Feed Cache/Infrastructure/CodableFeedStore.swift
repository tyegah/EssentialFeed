//
//  CodableFeedStore.swift
//  EssentialFeed
//
//  Created by Ty Septiani on 04/10/22.
//

import Foundation

public class CodableFeedStore: FeedStore {
    private struct Cache: Codable {
        let feed: [CodableFeedImage]
        let timestamp: Date
        
        var localFeed: [LocalFeedImage] {
            feed.map { $0.local }
        }
    }
    
    private struct CodableFeedImage:Codable {
        private let id: UUID
        private let description: String?
        private let location: String?
        private let url: URL
        
        init(_ image: LocalFeedImage) {
            self.id = image.id
            self.description = image.description
            self.location = image.location
            self.url = image.url
        }
        
        var local: LocalFeedImage {
            return LocalFeedImage(id: id, description: description, location: location, url: url)
        }
    }
    
    private let storeURL: URL
    
    public init(storeURL: URL) {
        self.storeURL = storeURL
    }
    
    private let queue = DispatchQueue(label: "\(CodableFeedStore.self)Queue", qos: .userInitiated, attributes: .concurrent)
    
    public func retrieve(completion: @escaping RetrievalCompletion) {
        let storeURL = self.storeURL
        queue.async {
            guard let data = try? Data(contentsOf: storeURL) else {
                return completion(.empty)
            }
            
            do {
                let decoder = JSONDecoder()
                let cache = try decoder.decode(Cache.self, from: data)
                completion(.found(cache.localFeed, cache.timestamp))
            }
            catch {
                completion(.failure(error))
            }
        }
    }
    
    public func insert(_ feed:[LocalFeedImage], timeStamp: Date, completion: @escaping InsertionCompletion) {
        let storeURL = self.storeURL
        // Barrier flags only for operations with side-effects
        queue.async(flags: .barrier) {
            do {
                let encoder = JSONEncoder()
                let encoded = try encoder.encode(Cache(feed: feed.map(CodableFeedImage.init), timestamp: timeStamp))
                try encoded.write(to: storeURL)
                completion(nil)
            }
            catch {
                completion(error)
            }
        }
    }
    
    
    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        let storeURL = self.storeURL
        // Barrier flags only for operations with side-effects
        queue.async(flags: .barrier) {
            guard FileManager.default.fileExists(atPath: storeURL.path) else {
                debugPrint("DELETE FAILED")
                return completion(nil)
            }
            
            do {
                try FileManager.default.removeItem(at: storeURL)
                debugPrint("DELETE COMPLETED")
                completion(nil)
            } catch {
                debugPrint("DELETE ERROR")
                completion(error)
            }
        }
    }
}
