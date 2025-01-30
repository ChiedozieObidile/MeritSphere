# MeritSphere: Advanced DAO Merit Tracking System

## Overview

MeritSphere is a sophisticated merit tracking system built on the Stacks blockchain, designed to quantify and reward member contributions within DAOs. The system implements a comprehensive point-based mechanism that accounts for various forms of participation, includes time-decay factors, and features multiple engagement incentives.

## Features

- **Multi-dimensional Merit Tracking**
  - Initiative creation and success tracking
  - Decision participation monitoring
  - Task completion recording
  - Peer recognition system

- **Advanced Scoring Mechanisms**
  - Time-based decay of merit points
  - Activity-based multipliers
  - Participation rate bonuses
  - Success-based rewards

- **Robust Governance Features**
  - Initiative status management
  - Configurable point parameters
  - Administrator controls
  - Member participation metrics

## Technical Architecture

### Core Data Structures

#### Member Metrics
```clarity
{
    merit-points: uint,
    initiatives-created: uint,
    decisions-made: uint,
    last-participation: uint,
    tasks-completed: uint,
    successful-initiatives: uint,
    decision-participation-rate: uint,
    peer-recognition: uint
}
```

#### Activity Points Configuration
```clarity
{
    base-points: uint,
    multiplier: uint,
    minimum-threshold: uint
}
```

#### Initiative Records
```clarity
{
    creator: principal,
    status: (string-ascii 12),
    decision-count: uint,
    created-at: uint
}
```

## Usage Guide

### Member Registration and Basic Actions

1. **Register as a Member**
```clarity
(contract-call? .merit-sphere register-member)
```

2. **Create an Initiative**
```clarity
(contract-call? .merit-sphere log-initiative u1)
```

3. **Participate in Decision Making**
```clarity
(contract-call? .merit-sphere log-decision u1)
```

4. **Complete Tasks**
```clarity
(contract-call? .merit-sphere log-task)
```

### Advanced Features

1. **Peer Recognition**
```clarity
(contract-call? .merit-sphere give-peer-recognition 'SP2ZNGJ85ENDY6QRHQ5P2D4FXKGZWCKTB2T0Z55KF)
```

2. **Check Current Merit Score**
```clarity
(contract-call? .merit-sphere get-current-merit 'SP2ZNGJ85ENDY6QRHQ5P2D4FXKGZWCKTB2T0Z55KF)
```

### Administrative Functions

1. **Update Initiative Status**
```clarity
(contract-call? .merit-sphere update-initiative-status u1 "successful")
```

2. **Adjust Point Parameters**
```clarity
(contract-call? .merit-sphere adjust-points-parameters "initiative" u10 u2 u5)
```

## Merit Calculation Mechanics

### Point Accumulation
- Base points awarded for each activity
- Multipliers based on participation frequency
- Bonus points for successful initiatives
- Additional points from peer recognition

### Time Decay
Merit points decay over time using the formula:
```clarity
(if (> decay-rate u0)
    (/ initial-points decay-rate)
    initial-points)
```

### Participation Rate
```clarity
(* (/ decisions total-initiatives) u100)
```

## Security Considerations

1. **Input Validation**
   - Initiative ID bounds checking
   - Point value limitations
   - Activity type verification

2. **Access Control**
   - Administrator-only functions
   - Self-registration protection
   - Duplicate entry prevention

3. **State Protection**
   - Status transition validation
   - Record existence verification
   - Principal verification

## Deployment

### Prerequisites
- Stacks blockchain environment
- Clarity contract deployment tools
- Administrative principal address

### Installation Steps
1. Deploy the contract to the Stacks blockchain
2. Initialize activity point parameters
3. Configure administrative controls
4. Begin member registration

## Contract Constants

```clarity
max-initiative-id: u1000000
max-points: u1000
```

## Error Codes

- `u100`: Admin-only access denied
- `u101`: Member not found
- `u102`: Access denied
- `u103`: Invalid merit value
- `u104`: Invalid parameter
- `u111`: Invalid initiative ID
- `u112`: Invalid activity type

## Testing

1. **Unit Tests**
   - Member registration flow
   - Initiative creation and management
   - Decision recording
   - Point calculation accuracy
   - Time decay implementation

2. **Integration Tests**
   - Full workflow scenarios
   - Administrative functions
   - State transitions
   - Error handling

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## Support

For support and questions, please create an issue in the repository

## Acknowledgments

- Stacks blockchain community
- DAO governance researchers
- Contributors and testers