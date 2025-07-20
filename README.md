# Decentralized Pet Licensing System

A blockchain-based pet licensing and management system built on the Stacks blockchain using Clarity smart contracts.

## Overview

This system provides a comprehensive solution for municipal pet licensing, tracking, and enforcement through five interconnected smart contracts:

1. **Pet Registration Contract** - Core licensing and vaccination tracking
2. **Renewal Notification Contract** - Automated license renewal reminders
3. **Lost Pet Recovery Contract** - Found animal identification and reunification
4. **Violation Enforcement Contract** - Citation management for unlicensed pets
5. **Shelter Coordination Contract** - Animal control and adoption services

## Features

### Pet Registration
- Issue unique pet licenses with blockchain verification
- Track vaccination records and requirements
- Store owner and pet information securely
- Generate tamper-proof license certificates

### Renewal Management
- Automated renewal notifications
- Grace period tracking
- Late fee calculations
- Bulk renewal processing

### Lost Pet Recovery
- Register found animals with location data
- Match lost pets with found reports
- Facilitate owner reunification
- Track recovery success rates

### Violation Enforcement
- Issue citations for unlicensed pets
- Track violation history
- Calculate penalties and fines
- Appeal process management

### Shelter Coordination
- Animal intake and processing
- Adoption tracking
- Euthanasia prevention protocols
- Inter-shelter transfers

## Contract Architecture

Each contract operates independently while maintaining data consistency through standardized data structures and validation rules.

### Data Types

- **Pet Records**: Unique identifiers, breed, age, vaccination status
- **Owner Information**: Contact details, address, license history
- **License Status**: Active, expired, suspended, revoked
- **Violation Records**: Citation details, fines, resolution status

## Getting Started

### Prerequisites

- Clarinet CLI installed
- Node.js 18+ for testing
- Stacks wallet for deployment

### Installation

\`\`\`bash
git clone <repository-url>
cd pet-licensing-system
npm install
clarinet check
\`\`\`

### Testing

\`\`\`bash
npm test
\`\`\`

### Deployment

\`\`\`bash
clarinet deploy --testnet
\`\`\`

## Usage Examples

### Register a New Pet

\`\`\`clarity
(contract-call? .pet-registration register-pet
"Buddy"
"Golden Retriever"
u3
"2024-01-15"
true)
\`\`\`

### Report a Lost Pet

\`\`\`clarity
(contract-call? .lost-pet-recovery report-lost
u12345
"Central Park"
"Last seen near playground")
\`\`\`

### Issue a Citation

\`\`\`clarity
(contract-call? .violation-enforcement issue-citation
'SP1234...
"Unlicensed pet"
u50)
\`\`\`

## Security Considerations

- All contracts implement proper access controls
- Owner verification required for sensitive operations
- Immutable audit trails for all transactions
- Protection against common smart contract vulnerabilities

## Contributing

Please read our contributing guidelines and submit pull requests for any improvements.

## License

MIT License - see LICENSE file for details
