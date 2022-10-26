//
//  FeedStore.swift
//  EssentialFeed
//
//  Created by Ty Septiani on 26/09/22.
//

import Foundation

public enum RetrievedCachedFeedResult {
    case failure(Error)
    case found([LocalFeedImage], Date)
    case empty
}

public protocol FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void
    typealias RetrievalCompletion = (RetrievedCachedFeedResult) -> Void
    
    /// Completion handler can be invoked in any thread
    /// The clients are responsible to dispatch to appropriate threads, if needed
    func deleteCachedFeed(completion: @escaping DeletionCompletion)
    
    /// Completion handler can be invoked in any thread
    /// The clients are responsible to dispatch to appropriate threads, if needed
    func insert(_ feed:[LocalFeedImage], timeStamp: Date, completion: @escaping InsertionCompletion)
    
    /// Completion handler can be invoked in any thread
    /// The clients are responsible to dispatch to appropriate threads, if needed
    func retrieve(completion: @escaping RetrievalCompletion)
}
