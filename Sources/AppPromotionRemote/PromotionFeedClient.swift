#if !os(Linux)
import Foundation
import CryptoKit
import AppPromotion

/// A successfully read catalog and its in-memory freshness lease; never a persistent ad cache.
public struct PromotionFeed: Sendable {
    public let catalog: PromotionCatalog
    public let fetchedAt: Date
    public let expiresAt: Date

    public func rotation(host: PromotionAppID, targets: [PromotionTarget], language: String) -> PromotionRotation {
        catalog.rotation(host: host, targets: targets, language: language,
                         notAfter: expiresAt, notBefore: fetchedAt)
    }

    public func rotation(host: PromotionAppID, language: String) -> PromotionRotation {
        catalog.rotation(host: host, language: language, notAfter: expiresAt, notBefore: fetchedAt)
    }
}

/// Public static hosting works with Cloudflare, Firebase Hosting or another approved HTTPS origin.
/// The client sends no host-app ID, locale, account identity or telemetry and does not retry.
public struct PromotionFeedClient: Sendable {
    public let endpoint: PromotionEndpoint

    public init(endpoint: PromotionEndpoint) {
        self.endpoint = endpoint
    }

    public func fetch() async throws -> PromotionFeed {
        let data = try await Self.read(endpoint.url, contentType: "application/json", maximumBytes: 32 * 1024)
        let catalog = try PromotionCatalog(data: data)
        let fetchedAt = Date()
        return PromotionFeed(catalog: catalog, fetchedAt: fetchedAt,
                             expiresAt: min(catalog.validUntil, fetchedAt.addingTimeInterval(300)))
    }

    /// Reads immutable artwork bytes. A cached image never authorizes displaying an expired card.
    public func fetchImage(_ asset: PromotionAsset) async throws -> Data {
        let url = try endpoint.imageURL(for: asset)
        let type = asset.path.hasSuffix(".png") ? "image/png" : "image/jpeg"
        let data = try await Self.read(url, contentType: type, maximumBytes: 96 * 1024)
        let digest = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        guard digest == asset.sha256 else { throw PromotionRemoteError.checksumMismatch }
        return data
    }

    private static func read(_ url: URL, contentType: String, maximumBytes: Int) async throws -> Data {
        try Task.checkCancellation()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpShouldSetCookies = false
        configuration.httpCookieStorage = nil
        configuration.urlCredentialStorage = nil
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.timeoutIntervalForRequest = 3
        configuration.timeoutIntervalForResource = 3
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }

        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 3)
        request.httpMethod = "GET"
        request.setValue(contentType, forHTTPHeaderField: "Accept")
        request.setValue("*", forHTTPHeaderField: "Accept-Language")
        request.setValue("AppPromotion/0.1", forHTTPHeaderField: "User-Agent")
        request.setValue("no-cache, no-store", forHTTPHeaderField: "Cache-Control")
        let (bytes, response) = try await session.bytes(for: request, delegate: RejectRedirects())
        guard let http = response as? HTTPURLResponse else { throw PromotionRemoteError.invalidResponse }
        if (300...399).contains(http.statusCode) { throw PromotionRemoteError.redirectRejected }
        guard http.statusCode == 200 else { throw PromotionRemoteError.httpStatus(http.statusCode) }
        guard http.url == url else { throw PromotionRemoteError.invalidResponse }
        guard http.mimeType?.lowercased() == contentType else { throw PromotionRemoteError.unexpectedContentType }
        guard http.expectedContentLength <= Int64(maximumBytes) else {
            throw PromotionRemoteError.sizeLimit(maximumBytes)
        }
        var data = Data()
        if http.expectedContentLength > 0 { data.reserveCapacity(Int(http.expectedContentLength)) }
        for try await byte in bytes {
            try Task.checkCancellation()
            guard data.count < maximumBytes else { throw PromotionRemoteError.sizeLimit(maximumBytes) }
            data.append(byte)
        }
        try Task.checkCancellation()
        return data
    }

    private final class RejectRedirects: NSObject, URLSessionTaskDelegate, Sendable {
        func urlSession(_ session: URLSession, task: URLSessionTask,
                        willPerformHTTPRedirection response: HTTPURLResponse,
                        newRequest request: URLRequest) async -> URLRequest? {
            nil
        }
    }
}
#endif
