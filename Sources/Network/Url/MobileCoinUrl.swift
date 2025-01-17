//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

protocol Scheme {
    static var secureScheme: String { get }
    static var insecureScheme: String { get }

    static var defaultSecurePort: Int { get }
    static var defaultInsecurePort: Int { get }
}

protocol MobileCoinUrlProtocol {
    var url: URL { get }
    var host: String { get }
    var port: Int { get }
    var useTls: Bool { get }
    var address: String { get }
    var httpBasedUrl: URL { get }
}

extension MobileCoinUrlProtocol {
    var address: String { "\(host):\(port)" }

    /// host:port
    var responderId: String { address }

    var httpBasedUrl: URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }

        components.scheme = self.useTls ? "https" : "http"
        if components.port == nil {
            switch (components.scheme, self.port) {
            case ("http", 80):
                break
            case ("https", 443):
                break
            case (_, let port):
                components.port = port
            }
        }

        guard let httpUrl = components.url else {
            return url
        }
        return httpUrl
    }
}

struct MobileCoinUrl<Scheme: MobileCoin.Scheme>: MobileCoinUrlProtocol {
    static func make(string: String) -> Result<MobileCoinUrl, InvalidInputError> {
        guard let url = URL(string: string) else {
            return .failure(InvalidInputError("Could not parse url: \(string)"))
        }

        let useTls: Bool
        switch url.scheme {
        case .some(Scheme.secureScheme):
            useTls = true
        case .some(Scheme.insecureScheme):
            useTls = false
        default:
            return .failure(InvalidInputError("Unrecognized scheme: \(string), expected: " +
                "[\"\(Scheme.secureScheme)\", \"\(Scheme.insecureScheme)\"]"))
        }

        guard let host = url.host, !host.isEmpty else {
            return .failure(InvalidInputError("Invalid host: \(string)"))
        }

        return .success(MobileCoinUrl(url: url, useTls: useTls, host: host))
    }

    let url: URL

    let useTls: Bool
    let host: String
    let port: Int

    private init(url: URL, useTls: Bool, host: String) {
        self.url = url
        self.useTls = useTls
        self.host = host

        if let port = url.port {
            self.port = port
        } else {
            self.port = self.useTls ? Scheme.defaultSecurePort : Scheme.defaultInsecurePort
        }
    }
}

struct AnyMobileCoinUrl: MobileCoinUrlProtocol {
    static func make(string: String) -> Result<AnyMobileCoinUrl, InvalidInputError> {
        make(string: string, useTlsOverride: nil)
    }

    static func make(string: String, useTls: Bool) -> Result<AnyMobileCoinUrl, InvalidInputError> {
        make(string: string, useTlsOverride: useTls)
    }

    // swiftlint:disable discouraged_optional_boolean
    private static func make(string: String, useTlsOverride: Bool?)
        -> Result<AnyMobileCoinUrl, InvalidInputError>
    {
    // swiftlint:enable discouraged_optional_boolean
        guard let url = URL(string: string) else {
            return .failure(InvalidInputError("Could not parse url: \(string)"))
        }

        guard let host = url.host, !host.isEmpty else {
            return .failure(InvalidInputError("Invalid host: \(string)"))
        }

        return .success(AnyMobileCoinUrl(url: url, host: host, useTlsOverride: useTlsOverride))
    }

    let url: URL

    let useTls: Bool
    let host: String
    let port: Int

    // swiftlint:disable discouraged_optional_boolean
    private init(url: URL, host: String, useTlsOverride: Bool?) {
    // swiftlint:enable discouraged_optional_boolean
        self.url = url
        self.host = host

        if let useTls = useTlsOverride {
            self.useTls = useTls
        } else {
            switch url.scheme {
            case "http":
                self.useTls = false
            case "https":
                self.useTls = true
            default:
                self.useTls = true
            }
        }

        if let port = url.port {
            self.port = port
        } else if !self.useTls {
            self.port = 80
        } else {
            self.port = 443
        }
    }
}

extension MobileCoinUrl: Equatable {}
extension MobileCoinUrl: Hashable {}
