import Foundation
import CoreServices

final class FileWatcher {
    private var stream: FSEventStreamRef?
    private let callback: () -> Void
    private let debounceInterval: TimeInterval
    private var debounceWorkItem: DispatchWorkItem?

    init(directory: URL, debounceInterval: TimeInterval = 0.3,
         callback: @escaping () -> Void) {
        self.callback = callback
        self.debounceInterval = debounceInterval
        startWatching(directory: directory)
    }

    private func startWatching(directory: URL) {
        let pathsToWatch = [directory.path as CFString] as CFArray
        var context = FSEventStreamContext()
        context.info = Unmanaged.passUnretained(self).toOpaque()

        guard let stream = FSEventStreamCreate(
            nil,
            { (_, info, _, _, _, _) in
                guard let info else { return }
                Unmanaged<FileWatcher>.fromOpaque(info)
                    .takeUnretainedValue().handleEvent()
            },
            &context, pathsToWatch,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow), 0.1,
            UInt32(kFSEventStreamCreateFlagUseCFTypes |
                   kFSEventStreamCreateFlagFileEvents |
                   kFSEventStreamCreateFlagNoDefer)
        ) else { return }

        self.stream = stream
        FSEventStreamSetDispatchQueue(stream, DispatchQueue.main)
        FSEventStreamStart(stream)
    }

    private func handleEvent() {
        debounceWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in self?.callback() }
        debounceWorkItem = item
        DispatchQueue.main.asyncAfter(
            deadline: .now() + debounceInterval, execute: item)
    }

    func stop() {
        guard let stream else { return }
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
        self.stream = nil
    }

    deinit { stop() }
}
