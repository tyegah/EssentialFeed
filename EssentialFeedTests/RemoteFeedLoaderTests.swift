//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Ty Septiani on 13/09/22.
//

import XCTest

class RemoteFeedLoader {
    func load() {
        HTTPClient.shared.get(from: URL(string: "https://a-url.com")!)
    }
}

class HTTPClient {
    static var shared = HTTPClient()
    
//    private init() {}
    
    func get(from url: URL) {
        
    }
}

// Move the test logic to a spy instead
class HTTPClientSpy: HTTPClient {
    var requestedURL: URL?
    
    override func get(from url: URL) {
        // We're moving the test logic from the RemoteFeedLoader to HTTPClient
        requestedURL = url //--> This is the test logic. This is created for testing purposes
    }
}

class RemoteFeedLoaderTests: XCTestCase {
    func test_init_doesNotRequestDataFromURL() {
        let client = HTTPClientSpy()
        HTTPClient.shared = client
        _ = RemoteFeedLoader()
        XCTAssertNil(client.requestedURL)
    }
    
    func test_load_requestsDataFromURL() {
        // Arrange
        let client = HTTPClientSpy()
        HTTPClient.shared = client
        let sut = RemoteFeedLoader()
        // Act
        sut.load()
        // Assert
        XCTAssertNotNil(client.requestedURL)
    }
}
