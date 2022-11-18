//
//  CoreDataFeedStore.swift
//  EssentialFeed
//
//  Created by Ty Septiani on 18/11/22.
//

import CoreData

public class CoreDataFeedStore: FeedStore {
    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext
    public init(storeURL: URL, bundle: Bundle = Bundle.main) throws {
        container = try NSPersistentContainer.load(modelName: "FeedStore",
                                                   url: storeURL,
                                                   in: bundle)
        context = container.newBackgroundContext()
    }
    
    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        perform { context in
            do {
                try ManagedCache.find(in: context).map(context.delete).map(context.save)
                completion(nil)
            }
            catch {
                completion(error)
            }
        }
    }
    
    public func insert(_ feed: [LocalFeedImage], timeStamp: Date, completion: @escaping InsertionCompletion) {
        perform { context in
            do {
                let managedCache = try ManagedCache.newUniqueInstance(in: context)
                managedCache.timestamp = timeStamp
                managedCache.feed = ManagedFeedImage.images(from: feed, in: context)
                
                try context.save()
                completion(nil)
            }
            catch {
                completion(error)
            }
        }
    }
    
    public func retrieve(completion: @escaping RetrievalCompletion) {
        perform { context in
            do {
                if let cache = try ManagedCache.find(in: context) {
                    completion(.found(cache.localFeed, cache.timestamp))
                }
                else {
                    completion(.empty)
                }
            }
            catch {
                completion(.failure(error))
            }
        }
    }
    
    private func perform(_ action: @escaping (NSManagedObjectContext) -> Void) {
        let context = self.context
        context.perform {
            action(context)
        }
    }
}

