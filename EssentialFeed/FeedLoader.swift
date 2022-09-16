//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Ty Septiani on 13/09/22.
//

import Foundation

// We need to make this LoadFeedResult to use Generic Type Error
// Because we are using the LoadFeedResult on the RemoteFeedLoader
//public typealias LoadFeedResult<Error:Swift.Error> = Swift.Result<[FeedItem], Error>

public enum LoadFeedResult<Error: Swift.Error> {
    case success([FeedItem])
    case failure(Error)
}

extension LoadFeedResult: Equatable where Error:Equatable {}

protocol FeedLoader {
    associatedtype Error: Swift.Error
    func load(completion: @escaping (LoadFeedResult<Error>) -> Void)
}
