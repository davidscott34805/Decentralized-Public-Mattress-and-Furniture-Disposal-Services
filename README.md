# Decentralized Public Mattress and Furniture Disposal Services

A blockchain-based system for coordinating sustainable disposal, recycling, and donation of mattresses and furniture items. This system helps prevent illegal dumping while promoting environmental responsibility and community support.

## System Overview

The platform consists of five interconnected smart contracts that manage different aspects of furniture and mattress disposal:

### 1. Mattress Recycling Coordination Contract
- Manages collection and recycling of old mattresses
- Prevents illegal dumping through proper tracking
- Coordinates with certified recycling facilities
- Tracks mattress lifecycle from pickup to processing

### 2. Furniture Donation Tracking Contract
- Coordinates donation of used furniture to charities
- Matches donors with families in need
- Maintains donation history and impact metrics
- Verifies recipient eligibility and donor authenticity

### 3. Bulk Item Pickup Scheduling Contract
- Manages curbside collection of large furniture and appliances
- Optimizes pickup routes and scheduling
- Handles capacity planning and resource allocation
- Provides real-time status updates to residents

### 4. Disposal Fee Collection Contract
- Processes fees for oversized item disposal and recycling
- Manages payment distribution to service providers
- Handles refunds and fee adjustments
- Maintains transparent pricing structure

### 5. Landfill Diversion Monitoring Contract
- Tracks success in diverting furniture and mattresses from landfills
- Generates environmental impact reports
- Monitors recycling and donation rates
- Provides data for policy decisions

## Key Features

- **Decentralized Coordination**: No single point of failure
- **Transparent Operations**: All activities recorded on blockchain
- **Environmental Impact Tracking**: Real-time diversion metrics
- **Community Support**: Facilitates furniture donations to those in need
- **Cost Efficiency**: Optimized routing and resource allocation
- **Compliance Monitoring**: Ensures proper disposal practices

## Contract Architecture

Each contract operates independently while sharing common data structures for interoperability:

- **Item Registration**: Standardized item categorization and tracking
- **Service Provider Network**: Verified recyclers, charities, and collectors
- **User Management**: Resident registration and verification
- **Payment Processing**: Secure fee collection and distribution
- **Reporting System**: Comprehensive analytics and monitoring

## Environmental Benefits

- Reduces illegal dumping incidents
- Increases recycling and donation rates
- Minimizes landfill waste
- Promotes circular economy principles
- Supports community welfare through donations

## Getting Started

1. Deploy contracts to Stacks blockchain
2. Register service providers (recyclers, charities, collectors)
3. Set up fee structures and service areas
4. Begin accepting disposal requests from residents
5. Monitor performance through built-in analytics

## Testing

The system includes comprehensive test coverage using Vitest:

\`\`\`bash
npm test
\`\`\`

## Configuration

- **Clarinet.toml**: Project configuration and contract definitions
- **Package.json**: Dependencies and test scripts
- **Contract Parameters**: Configurable fees, limits, and service areas
  
