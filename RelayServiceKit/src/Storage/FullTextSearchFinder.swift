//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

import Foundation

// Create a searchable index for objects of type T
public class SearchIndexer<T> {
    
    private let indexBlock: (T, YapDatabaseReadTransaction) -> String
    
    public init(indexBlock: @escaping (T, YapDatabaseReadTransaction) -> String) {
        self.indexBlock = indexBlock
    }
    
    public func index(_ item: T, transaction: YapDatabaseReadTransaction) -> String {
        return normalize(indexingText: indexBlock(item, transaction))
    }
    
    private func normalize(indexingText: String) -> String {
        return FullTextSearchFinder.normalize(text: indexingText)
    }
}

@objc
public class FullTextSearchFinder: NSObject {

    // MARK: - Querying

    // We want to match by prefix for "search as you type" functionality.
    // SQLite does not support suffix or contains matches.
    public class func query(searchText: String) -> String {
        // 1. Normalize the search text.
        //
        // TODO: We could arguably convert to lowercase since the search
        // is case-insensitive.
        let normalizedSearchText = FullTextSearchFinder.normalize(text: searchText)

        // 2. Split the non-numeric text into query terms (or tokens).
        let nonNumericText = String(String.UnicodeScalarView(normalizedSearchText.unicodeScalars.lazy.map {
            if CharacterSet.decimalDigits.contains($0) {
                return " "
            } else {
                return $0
            }
        }))
        var queryTerms = nonNumericText.split(separator: " ")

        // 3. Add an additional numeric-only query term.
        let digitsOnlyScalars = normalizedSearchText.unicodeScalars.lazy.filter {
            CharacterSet.decimalDigits.contains($0)
        }
        let digitsOnly: Substring = Substring(String(String.UnicodeScalarView(digitsOnlyScalars)))
        queryTerms.append(digitsOnly)

        // 4. De-duplicate and sort query terms.
        //    Duplicate terms are redundant.
        //    Sorting terms makes the output of this method deterministic and easier to test,
        //        and the order won't affect the search results.
        queryTerms = Array(Set(queryTerms)).sorted()

        // 5. Filter the query terms.
        let filteredQueryTerms = queryTerms.filter {
            // Ignore empty terms.
            $0.count > 0
        }.map {
            // Allow partial match of each term.
            //
            // Note that we use double-quotes to enclose each search term.
            // Quoted search terms can include a few more characters than
            // "bareword" (non-quoted) search terms.  This shouldn't matter,
            // since we're filtering all of the affected characters, but
            // quoting protects us from any bugs in that logic.
            "\"\($0)\"*"
        }

        // 6. Join terms into query string.
        let query = filteredQueryTerms.joined(separator: " ")
        return query
    }

    public func enumerateObjects(searchText: String, transaction: YapDatabaseReadTransaction, block: @escaping (Any, String) -> Void) {
        guard let ext: YapDatabaseFullTextSearchTransaction = ext(transaction: transaction) else {
            owsFail("\(logTag) ext was unexpectedly nil")
            return
        }

        let query = FullTextSearchFinder.query(searchText: searchText)

        Logger.verbose("\(logTag) query: \(query)")

        let maxSearchResults = 500
        var searchResultCount = 0
        let snippetOptions = YapDatabaseFullTextSearchSnippetOptions()
        snippetOptions.startMatchText = ""
        snippetOptions.endMatchText = ""
        ext.enumerateKeysAndObjects(matching: query, with: snippetOptions) { (snippet: String, _: String, _: String, object: Any, stop: UnsafeMutablePointer<ObjCBool>) in
            guard searchResultCount < maxSearchResults else {
                stop.pointee = true
                return
            }
            searchResultCount += 1

            block(object, snippet)
        }
    }

    // MARK: - Normalization

    fileprivate static var charactersToRemove: CharacterSet = {
        // * We want to strip punctuation - and our definition of "punctuation"
        //   is broader than `CharacterSet.punctuationCharacters`.
        // * FTS should be robust to (i.e. ignore) illegal and control characters,
        //   but it's safer if we filter them ourselves as well.
        var charactersToFilter = CharacterSet.punctuationCharacters
        charactersToFilter.formUnion(CharacterSet.illegalCharacters)
        charactersToFilter.formUnion(CharacterSet.controlCharacters)

        // We want to strip all ASCII characters except:
        // * Letters a-z, A-Z
        // * Numerals 0-9
        // * Whitespace
        var asciiToFilter = CharacterSet(charactersIn: UnicodeScalar(0x0)!..<UnicodeScalar(0x80)!)
        assert(!asciiToFilter.contains(UnicodeScalar(0x80)!))
        asciiToFilter.subtract(CharacterSet.alphanumerics)
        asciiToFilter.subtract(CharacterSet.whitespacesAndNewlines)
        charactersToFilter.formUnion(asciiToFilter)

        return charactersToFilter
    }()

    public class func normalize(text: String) -> String {
        // 1. Filter out invalid characters.
        let filtered = text.unicodeScalars.lazy.filter({
            !charactersToRemove.contains($0)
        })

        // 2. Simplify whitespace.
        let simplifyingFunction: (UnicodeScalar) -> UnicodeScalar = {
            if CharacterSet.whitespacesAndNewlines.contains($0) {
                return UnicodeScalar(" ")
            } else {
                return $0
            }
        }
        let simplified = filtered.map(simplifyingFunction)

        // 3. Strip leading & trailing whitespace last, since we may replace
        // filtered characters with whitespace.
        let result = String(String.UnicodeScalarView(simplified))
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Index Building

    private class var contactsManager: ContactsManagerProtocol {
        return TextSecureKitEnv.shared().contactsManager
    }
    
    private static let threadIndexer: SearchIndexer<TSThread> = SearchIndexer { (thread: TSThread, transaction: YapDatabaseReadTransaction) in
        let title = thread.title ?? ""

        var participantsStrings: String = ""
        for recipientId in thread.participantIds {
            if let recipient = contactsManager.recipient(withId:recipientId, transaction: transaction) {
                let memberString = recipientIndexer.index(recipient, transaction: transaction)
                participantsStrings.append(" \(memberString)")
            }

        }
        
        return "\(title) \(participantsStrings)"
    }

    private static let recipientIndexer: SearchIndexer<RelayRecipient> = SearchIndexer { (recipient: RelayRecipient, transaction: YapDatabaseReadTransaction) in
        let fullName = recipient.fullName()
        let slug:String  = recipient.flTag?.displaySlug ?? ""
        return "\(fullName) \(slug)"
    }

    private static let messageIndexer: SearchIndexer<TSMessage> = SearchIndexer { (message: TSMessage, transaction: YapDatabaseReadTransaction) in
        if let body = message.plainTextBody, body.count > 0 {
            return body
        }
        if let oversizeText = oversizeText(forMessage: message) {
            return oversizeText
        }
        return ""
    }

    private static func oversizeText(forMessage message: TSMessage) -> String? {
        guard message.hasAttachments() else {
            return nil
        }
        let dbConnection = OWSPrimaryStorage.shared().dbReadConnection
        var oversizeText: String?
        dbConnection.read({ (transaction) in
            guard let attachment = message.attachment(with: transaction) else {
                // This can happen during the initial save of incoming messages.
                Logger.warn("Could not load attachment for search indexing.")
                return
            }
            guard let attachmentStream = attachment as? TSAttachmentStream else {
                return
            }
            guard attachmentStream.isOversizeText() else {
                return
            }
            guard let text = attachmentStream.readOversizeText() else {
                owsFail("Could not load oversize text attachment")
                return
            }
            oversizeText = text
        })
        return oversizeText
    }

    private class func indexContent(object: Any, transaction: YapDatabaseReadTransaction) -> String? {
        if let thread = object as? TSThread {
            return self.threadIndexer.index(thread, transaction: transaction)
        } else if let message = object as? TSMessage {
            return self.messageIndexer.index(message, transaction: transaction)
        } else if let recipient = object as? RelayRecipient {
            return self.recipientIndexer.index(recipient, transaction: transaction)
        } else {
            return nil
        }
    }

    // MARK: - Extension Registration

    private static let dbExtensionName: String = "FullTextSearchFinderExtension"

    private func ext(transaction: YapDatabaseReadTransaction) -> YapDatabaseFullTextSearchTransaction? {
        return transaction.ext(FullTextSearchFinder.dbExtensionName) as? YapDatabaseFullTextSearchTransaction
    }

    @objc
    public class func asyncRegisterDatabaseExtension(storage: OWSStorage) {
        storage.asyncRegister(dbExtensionConfig, withName: dbExtensionName)
    }

    // Only for testing.
    public class func ensureDatabaseExtensionRegistered(storage: OWSStorage) {
        guard storage.registeredExtension(dbExtensionName) == nil else {
            return
        }

        storage.register(dbExtensionConfig, withName: dbExtensionName)
    }

    private class var dbExtensionConfig: YapDatabaseFullTextSearch {
        AssertIsOnMainThread(file: #function)

        let contentColumnName = "content"
        let handler = YapDatabaseFullTextSearchHandler.withObjectBlock { (transaction: YapDatabaseReadTransaction, dict: NSMutableDictionary, _: String, _: String, object: Any) in
            if let content: String = indexContent(object: object, transaction: transaction) {
                dict[contentColumnName] = content
            }
        }
        // update search index on contact name changes?

        return YapDatabaseFullTextSearch(columnNames: ["content"],
                                         options: nil,
                                         handler: handler,
                                         ftsVersion: YapDatabaseFullTextSearchFTS5Version,
                                         versionTag: "1")
    }
}
