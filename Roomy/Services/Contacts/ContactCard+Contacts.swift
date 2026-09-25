// Why: the scan and the merge must read a card the same way, or a card would look "changed since the scan"
// when only the reading differed. Both build their `ContactCard` here, from the same keys.
import Contacts

nonisolated extension ContactCard {
    /// Every key `init(_:isInDefaultContainer:)` reads. Reading a key that was not fetched raises an exception.
    static var contactKeys: [CNKeyDescriptor] {
        [
            CNContactIdentifierKey as CNKeyDescriptor,
            CNContactOrganizationNameKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor,
            CNContactImageDataAvailableKey as CNKeyDescriptor,
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
        ]
    }

    init(_ contact: CNContact, isInDefaultContainer: Bool = false) {
        self.init(
            id: contact.identifier,
            name: CNContactFormatter.string(from: contact, style: .fullName) ?? "",
            organization: contact.organizationName,
            phones: contact.phoneNumbers.map { $0.value.stringValue },
            emails: contact.emailAddresses.map { $0.value as String },
            hasImage: contact.imageDataAvailable,
            isInDefaultContainer: isInDefaultContainer)
    }
}
