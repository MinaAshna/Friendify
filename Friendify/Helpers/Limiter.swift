import Foundation

actor Limiter {
    private let policy: Policy
    private let duration: TimeInterval
    private var task: Task<Void, Error>?

    init(policy: Policy, duration: TimeInterval) {
        self.policy = policy
        self.duration = duration
    }

    func submit(operation: @escaping () async -> Void) {
        switch policy {
        case .throttle: throttle(operation: operation)
        case .debounce: debounce(operation: operation)
        }
    }
}

// MARK: - Limiter.Policy
extension Limiter {
    enum Policy {
        case throttle
        case debounce
    }
}

// MARK: - Private utility methods
private extension Limiter {
    func throttle(operation: @escaping () async -> Void) {
        guard task == nil else {
            return
        }
        task = Task {
            try? await Task.sleep(seconds: duration)
            task = nil
        }
        Task {
            await operation()
        }
    }

    func debounce(operation: @escaping () async -> Void) {
        task = Task {
            do {
                try await Task.sleep(seconds: duration)
                await operation()
                task = nil
            } catch {
                print(error.localizedDescription)
            }
        }
    }

}

// MARK: - TimeInterval
extension TimeInterval {
    static let nanosecondsPerSecond = TimeInterval(NSEC_PER_SEC)
}

extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: Double) async throws {
        let duration = UInt64(seconds * 1_000_000_000)
        try await Task.sleep(nanoseconds: duration)
    }
}


extension Task where Failure == Error {
    static func delayed(
        byTimeInterval delayInterval: TimeInterval,
        priority: TaskPriority? = nil,
        operation: @escaping @Sendable () async throws -> Success
    ) -> Task {
        Task(priority: priority) {
            let delay = UInt64(delayInterval * 1_000_000_000)
            try await Task<Never, Never>.sleep(nanoseconds: delay)
            return try await operation()
        }
    }
}
