# MilestoneEscrow Smart Contract

A decentralized milestone-based crowdfunding smart contract built on the Stacks blockchain using Clarity.

## Overview

MilestoneEscrow enables creators to launch campaigns with fixed funding goals, allowing backers to pledge STX into an escrow system. Funds are released only when milestones are approved by the backer community, ensuring accountability and trust.

## Features

✅ **Campaign Management**
- Create campaigns with funding goals and deadlines
- Track campaign status (active/failed)
- Automated deadline validation

✅ **Escrow System**
- Secure STX transfers into contract escrow
- Multi-backer pledge tracking
- Prevent unauthorized fund access

✅ **Backer Participation**
- Multiple backers can pledge to the same campaign
- Track individual backer contributions
- Maintain backer statistics per campaign

✅ **Milestone Tracking**
- Define target milestones for each campaign
- Track milestone completion and approvals
- Support majority-based approval mechanism

✅ **Refund Protection**
- Automatic campaign failure detection
- Refund mechanism when goals aren't met by deadline
- Protect backer investments

## Contract Functions

### Public Functions

#### `create-campaign`
```clarity
(create-campaign (goal uint) (deadline uint) (target-milestones uint))
