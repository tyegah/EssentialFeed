//
//  FeedStore.swift
//  EssentialFeed
//
//  Created by Ty Septiani on 26/09/22.
//

import Foundation

public protocol FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void
    func deleteCachedFeed(completion: @escaping DeletionCompletion)
    func insert(_ items:[FeedItem], timeStamp: Date, completion: @escaping InsertionCompletion)
}
