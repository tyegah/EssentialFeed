//
//  CoreDataFeedStore.swift
//  EssentialFeed
//
//  Created by Ty Septiani on 18/11/22.
//

import Foundation
import CoreData

@objc(ManagedCache)
private class ManagedCache: NSManagedObject {
    @NSManaged var timestamp: Date
    @NSManaged var feed: NSOrderedSet
}

@objc(ManagedFeedImage)
private class ManagedFeedImage: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var imageDescription: String?
    @NSManaged var location: String?
    @NSManaged var url: URL
    @NSManaged var cache: ManagedCache
}

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
        
    }
    
    public func insert(_ feed: [LocalFeedImage], timeStamp: Date, completion: @escaping InsertionCompletion) {
        let context = self.context
        context.perform {
            do {
                let managedCache = ManagedCache(context: context)
                managedCache.timestamp = timeStamp
                
                managedCache.feed = NSOrderedSet(array: feed.map { local in
                    let managedFeed = ManagedFeedImage(context: context)
                    managedFeed.id = local.id
                    managedFeed.imageDescription = local.description
                    managedFeed.location = local.location
                    managedFeed.url = local.url
                    return managedFeed
                })
                
                try context.save()
                completion(nil)
            }
            catch {
                completion(error)
            }
        }
    }
    
    public func retrieve(completion: @escaping RetrievalCompletion) {
        let context = self.context
        context.perform {
            do {
                let request = NSFetchRequest<ManagedCache>(entityName: ManagedCache.entity().name!)
                request.returnsObjectsAsFaults = false
                if let cache = try context.fetch(request).first {
                    completion(.found(cache.feed
                        .compactMap{
                        ($0 as? ManagedFeedImage)
                        }
                        .map {
                            LocalFeedImage(id: $0.id,
                                           description: $0.imageDescription,
                                           location: $0.location,
                                           url: $0.url)
                        }, cache.timestamp))
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
}

private extension NSPersistentContainer {
    enum LoadingError: Swift.Error {
        case modelNotFound
        case failedToLoadPersistentStores(Swift.Error)
    }
    
    static func load(modelName name: String, url: URL, in bundle: Bundle) throws -> NSPersistentContainer {
        guard let model = NSManagedObjectModel.with(name: name, in: bundle) else {
            throw LoadingError.modelNotFound
        }
        
        let description = NSPersistentStoreDescription(url: url)
        let container = NSPersistentContainer(name: name, managedObjectModel: model)
        container.persistentStoreDescriptions = [description]
        var loadError: Swift.Error?
        container.loadPersistentStores { loadError = $1 }
        try loadError.map { throw LoadingError.failedToLoadPersistentStores($0) }
        return container
    }
}

private extension NSManagedObjectModel {
    static func with(name:String, in bundle: Bundle) -> NSManagedObjectModel? {
        return bundle.url(forResource: name, withExtension: "momd").flatMap { NSManagedObjectModel(contentsOf: $0) }
    }
}
