import Foundation

public extension Api {
    
    func getAccountInfo(account: String, onComplete: @escaping (Result<BufferInfoPureData, Error>) -> Void) {
        let configs = RequestConfiguration(encoding: "base64")
        router.request(parameters: [account, configs]) { (result: Result<Rpc<BufferInfoPureData?>, Error>) in
            switch result {
            case let .success(rpc):
                guard let value = rpc.value else {
                    onComplete(.failure(SolanaError.nullValue))
                    return
                }
                onComplete(.success(value))
            case let .failure(error):
                onComplete(.failure(error))
            }
        }
    }
    
    func getAccountInfo<T: BufferLayout>(account: String, decodedTo: T.Type, onComplete: @escaping (Result<BufferInfo<T>, Error>) -> Void) {
        let configs = RequestConfiguration(encoding: "base64")
        router.request(parameters: [account, configs]) { (result: Result<Rpc<BufferInfo<T>?>, Error>) in
            switch result {
            case let .success(rpc):
                guard let value = rpc.value else {
                    onComplete(.failure(SolanaError.nullValue))
                    return
                }
                onComplete(.success(value))
            case let .failure(error):
                onComplete(.failure(error))
            }
        }
    }

    func getAccountInfo<T: BufferLayout>(account: String, decodedTo: T.Type, allowUnfundedRecipient: Bool = false, onComplete: @escaping (Result<BufferInfo<T>?, Error>) -> Void) {
        let configs = RequestConfiguration(encoding: "base64")
        router.request(parameters: [account, configs]) { (result: Result<Rpc<BufferInfo<T>?>, Error>) in
            switch result {
            case let .success(rpc):
                if allowUnfundedRecipient == false && rpc.value == nil {
                    onComplete(.failure(SolanaError.nullValue))
                    return
                }
                onComplete(.success(rpc.value))
            case let .failure(error):
                onComplete(.failure(error))
            }
        }
    }
}

@available(iOS 13.0, *)
@available(macOS 10.15, *)
public extension Api {
    func getAccountInfo<T: BufferLayout>(account: String, decodedTo: T.Type = T.self) async throws -> BufferInfo<T> {
        try await withCheckedThrowingContinuation { c in
            self.getAccountInfo(account: account, decodedTo: decodedTo, onComplete: c.resume(with:))
        }
    }
}

public extension ApiTemplates {
    struct GetAccountInfo<T: BufferLayout>: ApiTemplate {
        public init(account: String, decodedTo: T.Type) {
            self.account = account
            self.decodedTo = decodedTo
        }

        public let account: String
        public let decodedTo: T.Type

        public typealias Success = BufferInfo<T>

        public func perform(withConfigurationFrom apiClass: Api, completion: @escaping (Result<Success, Error>) -> Void) {
            apiClass.getAccountInfo(account: account, decodedTo: decodedTo.self, onComplete: completion)
        }
    }
}
