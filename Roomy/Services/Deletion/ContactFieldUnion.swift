// Why: a merge must not lose data. Every multi-value field of the removed cards is folded into the kept card
// through `MergeUnion`, the function the preview uses, so the written card equals the approved one. Every
// single-value field Roomy can read fills only gaps, never overwrites. Notes are the exception: iOS lets
// only entitled apps read them, so they cannot be carried over.
import Contacts

nonisolated enum ContactFieldUnion {
    /// Every key `fold` reads or writes. Reading a key that was not fetched raises an exception, so the merge
    /// fetches exactly these (plus the scan and vCard keys).
    static var keys: [CNKeyDescriptor] {
        [
            CNContactNamePrefixKey, CNContactGivenNameKey, CNContactMiddleNameKey, CNContactFamilyNameKey,
            CNContactPreviousFamilyNameKey, CNContactNameSuffixKey, CNContactNicknameKey,
            CNContactPhoneticGivenNameKey, CNContactPhoneticMiddleNameKey, CNContactPhoneticFamilyNameKey,
            CNContactPhoneticOrganizationNameKey, CNContactOrganizationNameKey, CNContactJobTitleKey,
            CNContactDepartmentNameKey, CNContactPhoneNumbersKey, CNContactEmailAddressesKey,
            CNContactPostalAddressesKey, CNContactUrlAddressesKey, CNContactSocialProfilesKey,
            CNContactInstantMessageAddressesKey, CNContactRelationsKey, CNContactDatesKey, CNContactBirthdayKey,
            CNContactNonGregorianBirthdayKey, CNContactImageDataKey,
        ].map { $0 as CNKeyDescriptor }
    }

    /// Single-value text fields that fill a gap on the kept card. Given and family name move together.
    private static var textFields: [ReferenceWritableKeyPath<CNMutableContact, String>] {
        [
            \.namePrefix, \.middleName, \.nameSuffix, \.nickname, \.previousFamilyName, \.phoneticGivenName,
            \.phoneticMiddleName, \.phoneticFamilyName, \.phoneticOrganizationName, \.organizationName, \.jobTitle,
            \.departmentName,
        ]
    }

    static func fold(_ extras: [CNContact], into kept: CNMutableContact, region: String) {
        foldValues(of: extras, into: kept, region: region)
        for extra in extras {
            guard let extra = extra.mutableCopy() as? CNMutableContact else { continue }
            fillGaps(from: extra, into: kept)
        }
    }

    private static func foldValues(of extras: [CNContact], into kept: CNMutableContact, region: String) {
        kept.phoneNumbers = union(kept.phoneNumbers, extras.map(\.phoneNumbers)) {
            ContactNormalizer.phoneIdentity($0.value.stringValue, region: region)
        }
        kept.emailAddresses = union(kept.emailAddresses, extras.map(\.emailAddresses)) {
            ContactNormalizer.emailIdentity($0.value as String)
        }
        kept.postalAddresses = union(kept.postalAddresses, extras.map(\.postalAddresses)) {
            CNPostalAddressFormatter.string(from: $0.value, style: .mailingAddress).lowercased()
        }
        kept.urlAddresses = union(kept.urlAddresses, extras.map(\.urlAddresses)) { ($0.value as String).lowercased() }
        kept.socialProfiles = union(kept.socialProfiles, extras.map(\.socialProfiles)) {
            "\($0.value.service)|\($0.value.username)|\($0.value.urlString)".lowercased()
        }
        kept.instantMessageAddresses = union(kept.instantMessageAddresses, extras.map(\.instantMessageAddresses)) {
            "\($0.value.service)|\($0.value.username)".lowercased()
        }
        // The label is part of a relation or a date: "Jane, sister" and "Jane, mother" are two people.
        kept.contactRelations = union(kept.contactRelations, extras.map(\.contactRelations)) {
            "\($0.label ?? "")|\($0.value.name)".lowercased()
        }
        kept.dates = union(kept.dates, extras.map(\.dates)) {
            "\($0.label ?? "")|\($0.value.year)-\($0.value.month)-\($0.value.day)"
        }
    }

    private static func fillGaps(from extra: CNMutableContact, into kept: CNMutableContact) {
        if kept.givenName.isEmpty && kept.familyName.isEmpty {
            kept.givenName = extra.givenName
            kept.familyName = extra.familyName
        }
        for field in textFields where kept[keyPath: field].isEmpty {
            kept[keyPath: field] = extra[keyPath: field]
        }
        if kept.birthday == nil { kept.birthday = extra.birthday }
        if kept.nonGregorianBirthday == nil { kept.nonGregorianBirthday = extra.nonGregorianBirthday }
        if kept.imageData == nil { kept.imageData = extra.imageData }
    }

    /// Kept values stay as they are; added values are re-created because a labeled value belongs to the card
    /// it was fetched with.
    private static func union<Value>(
        _ kept: [CNLabeledValue<Value>], _ extras: [[CNLabeledValue<Value>]],
        key: (CNLabeledValue<Value>) -> String
    ) -> [CNLabeledValue<Value>] {
        MergeUnion.merge(kept: kept, extras: extras, key: key).map { entry in
            entry.isAdded ? CNLabeledValue(label: entry.value.label, value: entry.value.value) : entry.value
        }
    }
}
