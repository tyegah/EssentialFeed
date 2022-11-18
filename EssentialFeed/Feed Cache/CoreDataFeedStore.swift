//
//  CoreDataFeedStore.swift
//  EssentialFeed
//
//  Created by Ty Septiani on 18/11/22.
//

import Foundation

public class CoreDataFeedStore: FeedStore {
    public init() {
        
    }
    
    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        
    }
    
    public func insert(_ feed: [LocalFeedImage], timeStamp: Date, completion: @escaping InsertionCompletion) {
        
    }
    
    public func retrieve(completion: @escaping RetrievalCompletion) {
        completion(.empty)
    }
}
