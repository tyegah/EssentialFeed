//
//  URLSessionHTTPClient.swift
//  EssentialFeedTests
//
//  Created by Ty Septiani on 17/09/22.
//

import XCTest
import EssentialFeed

class URLSessionHTTPClient {
    private let session: URLSession
    init(session: URLSession) {
        self.session = session
    }
    
    func get(from url: URL) {
        session.dataTask(with: url) { _, _, _ in
            
        }
    }
}

class URLSessionHTTPClientTests: XCTestCase {
    func test_getFromURL_createsDataTaskWithURL() {
        // ARRANGE
        let url = URL(string: "https://a-url.com")!
        // Here we're using subclass-based mocking which would be
        // URLSessionSpy
        let session = URLSessionSpy()
        let sut = URLSessionHTTPClient(session: session)
        sut.get(from: url)
        XCTAssertEqual(session.requestedURLs, [url])
    }
    
    private class URLSessionSpy: URLSession {
        var requestedURLs = [URL]()
        override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
            requestedURLs.append(url)
            return FakeURLSessionDataTask()
        }
    }
    
    // We use this fake class because we don't actually want to hit the real url endpoint
    // But when we start mocking classes we don't own, it can become dangerous
    // Because these classes often have a bunch of methods that we don't override, and overriding the behavior can also be dangerous
    private class FakeURLSessionDataTask: URLSessionDataTask {
        
    }
}
