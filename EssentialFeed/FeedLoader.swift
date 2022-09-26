//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Ty Septiani on 13/09/22.
//

import Foundation

// We need to make this LoadFeedResult to use Generic Type Error
// Because we are using the LoadFeedResult on the RemoteFeedLoader
// Notice that we're making this LoadFeedResult as equatable because of the tests but we actually don't have to
// Changing production code to conform to a protocol just because of a test is not good

//public enum LoadFeedResult<Error: Swift.Error> {
//    case success([FeedItem])
//    case failure(Error)
//}

// Now we're gonna remove this line and this will break some test
//extension LoadFeedResult: Equatable where Error:Equatable {}

// Using the typealias instead of enum because the Generic Error type is removed
public typealias LoadFeedResult = Swift.Result<[FeedImage], Error>


public protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
