//
//  FeedStoreSpy.swift
//  EssentialFeedTests
//
//  Created by Ty Septiani on 27/09/22.
//

import Foundation
import EssentialFeed

// Collaborator
//** This class (FeedStore class) is created since the beginning and we're not using spy to test drive
//** Later on it will be changed into FeedStoreSpy
//** Then it's moved into the test class

class FeedStoreSpy: FeedStore {
    var deletionCompletions = [DeletionCompletion]()
    var insertionCompletions = [InsertionCompletion]()
    var retrievalCompletions = [RetrievalCompletion]()
//    var insertions = [(items:[FeedItem], timeStamp: Date)]()
    //** Because the LocalFeedLoader is calling multiple methods of the FeedStore
    //** and they need to be in the right order
    //** We can actually merged the deletion and insertion checks using one variable to guarantee that the received messages are right (which methods are invoke with which values, and in which order)
    //** Thus, we create this variable
    var receivedMessages = [ReceivedMessage]()
    
    enum ReceivedMessage:Equatable {
        case deleteCacheFeed
        case insert([LocalFeedImage], Date)
        case retrieve
    }
    
    // delete
    func deleteCachedFeed(completion: @escaping DeletionCompletion) {
//        deleteCachedFeedCallCount += 1
        deletionCompletions.append(completion)
        receivedMessages.append(.deleteCacheFeed)
    }
    
    func completeDeletion(with error: Error, at index:Int = 0) {
        deletionCompletions[index](error)
    }
    
    func completeDeletionSuccessfully(at index:Int = 0) {
        deletionCompletions[index](nil)
    }
    
    // insert
    func insert(_ localImageFeed:[LocalFeedImage], timeStamp: Date, completion: @escaping InsertionCompletion) {
        insertionCompletions.append(completion)
        receivedMessages.append(.insert(localImageFeed, timeStamp))
    }
    
    func completeInsertion(with error: Error, at index: Int = 0) {
        insertionCompletions[index](error)
    }
    
    func completeInsertionSuccessfully(at index:Int = 0) {
        insertionCompletions[index](nil)
    }
    
    // retrieve
    func retrieve(completion: @escaping RetrievalCompletion) {
        receivedMessages.append(.retrieve)
        retrievalCompletions.append(completion)
    }
    
    func completeRetrieval(with error: Error, at index: Int = 0) {
        retrievalCompletions[index](error)
    }
    
    func completeRetrievalWithEmptyCache(at index: Int = 0) {
        retrievalCompletions[index](nil)
    }
}
