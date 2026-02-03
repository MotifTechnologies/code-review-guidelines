# Team Patterns & Case Studies: Solving Review Bottlenecks

## Overview

Different team structures and product types require different approaches to code review. This document presents real-world patterns from various team configurations.

---

## Team Archetypes & Solutions

### 1. Fast-Moving Startup (5-15 engineers)

#### Context
- Small team, everyone knows the codebase
- High trust environment
- Speed is critical (racing competition)
- Product-market fit still being found
- Frequent pivots

#### Problems
- Can't wait days for review
- Sometimes only 1 person knows an area
- Context switches expensive
- Need to ship daily

#### Solution: Trust-First Review

**Process:**
```
Ship/Show/Ask as default:
- 70% Ship (merge immediately, notify)
- 25% Show (merge within hours, async review)
- 5% Ask (wait for approval)
```

**Implementation:**
```typescript
// PR template forces decision
## Review Type
- [x] SHIP: Merging immediately (trivial/urgent)
- [ ] SHOW: Merging in 4h, review async
- [ ] ASK: Waiting for approval

If SHIP/SHOW, explain why: "Hotfix for customer-blocking bug"
```

**Safety Nets:**
- Comprehensive test suite (80%+ coverage)
- Feature flags for all new features
- Easy rollback (one-click revert)
- Monitoring & alerting
- Post-deploy review in Slack

**Daily Routine:**
```
9am: Ship code
10am: Team standup, mention what you shipped
11am: Async review of yesterday's ships
12pm: Address feedback in follow-up PRs
```

**Results:**
- Deploy 10-20x per day
- Review doesn't block shipping
- Issues caught quickly
- Team learns through review

---

### 2. Enterprise Product Team (50-200 engineers)

#### Context
- Large, mature codebase
- Multiple teams owning different areas
- Strict compliance requirements
- Slower release cycles (weekly/biweekly)
- High quality bar (enterprise customers)

#### Problems
- Code ownership unclear
- Review takes 2-3 days
- Too many reviewers required
- Large PRs common
- Knowledge silos

#### Solution: Tiered Review with Ownership

**Process:**
```
Automatic tier assignment based on:
1. File patterns (CODEOWNERS)
2. Risk score (size, area, author seniority)
3. Compliance requirements
```

**Risk Scoring:**
```python
def calculate_risk_tier(pr):
    score = 0

    # Size
    if pr.lines_changed > 1000:
        score += 50
    elif pr.lines_changed > 400:
        score += 20

    # Areas touched
    if any('auth' in f for f in pr.files):
        score += 40
    if any('payment' in f for f in pr.files):
        score += 40
    if any('.sql' in f or 'migration' in f for f in pr.files):
        score += 30

    # Author experience
    if pr.author.tenure_months < 6:
        score += 20
    elif pr.author.tenure_months > 24:
        score -= 15

    # Test coverage
    if pr.has_tests:
        score -= 10

    # History
    if pr.author.recent_reverts > 2:
        score += 25

    if score < 20:
        return 'auto-merge'
    elif score < 40:
        return 'quick-review'
    elif score < 70:
        return 'standard-review'
    else:
        return 'full-review'
```

**Tier Implementation:**
```yaml
# .github/review-tiers.yml
tiers:
  auto-merge:
    approvals_required: 0
    sla_hours: 0
    reviewers: []
    automation:
      - auto-format
      - security-scan
      - test-coverage-check

  quick-review:
    approvals_required: 1
    sla_hours: 4
    reviewers:
      - any-from: team-members
    automation:
      - auto-format
      - security-scan
      - test-coverage-check

  standard-review:
    approvals_required: 2
    sla_hours: 24
    reviewers:
      - from: code-owners
      - any-from: team-members
    automation:
      - auto-format
      - security-scan
      - test-coverage-check
      - performance-test

  full-review:
    approvals_required: 3
    sla_hours: 48
    reviewers:
      - from: code-owners
      - from: security-team
      - from: architect-team
    automation:
      - auto-format
      - security-scan
      - test-coverage-check
      - performance-test
      - compliance-check
```

**CODEOWNERS with Tiers:**
```
# Quick review (1 approver)
/docs/ @tech-writers
/tests/ @qa-team
*.md @tech-writers

# Standard review (2 approvers)
/src/api/ @api-team @backend-team
/src/ui/ @frontend-team @design-system-team

# Full review (3+ approvers)
/src/auth/ @security-team @backend-team @architect-team
/src/payments/ @payments-team @security-team @compliance-team
/migrations/ @database-team @backend-team @architect-team
```

**Review Assignment Algorithm:**
```python
def assign_reviewers(pr):
    tier = calculate_risk_tier(pr)
    required_reviewers = []

    # Get code owners
    for file in pr.files:
        owners = get_owners(file)
        required_reviewers.extend(owners)

    # Remove duplicates and author
    required_reviewers = list(set(required_reviewers) - {pr.author})

    # Load balance
    reviewers_with_load = [
        (r, get_pending_review_count(r))
        for r in required_reviewers
    ]
    reviewers_with_load.sort(key=lambda x: x[1])

    # Assign based on tier
    if tier == 'quick-review':
        return [reviewers_with_load[0][0]]
    elif tier == 'standard-review':
        return [r[0] for r in reviewers_with_load[:2]]
    else:  # full-review
        return [r[0] for r in reviewers_with_load[:3]]
```

**Results:**
- 30% of PRs auto-merge
- 50% quick review (same-day merge)
- 15% standard review (1-day cycle)
- 5% full review (2-day cycle)
- Clear expectations by tier
- Reduced review bottlenecks

---

### 3. Open Source Project (Distributed Contributors)

#### Context
- Contributors across timezones
- Varying skill levels
- No shared work hours
- Maintainer burnout common
- Quality must be maintained

#### Problems
- Maintainers overwhelmed
- Review takes weeks
- Contributors lose interest
- Hard to scale review capacity

#### Solution: Community-Driven Review + Automation

**Bot-First Review:**
```yaml
# .github/workflows/auto-review.yml
name: Automated Review

on: pull_request

jobs:
  auto-review:
    runs-on: ubuntu-latest
    steps:
      # Format check
      - name: Format
        run: npm run format:check

      # Lint
      - name: Lint
        run: npm run lint

      # Tests
      - name: Test
        run: npm test

      # Security scan
      - name: Security
        uses: snyk/actions/node@master

      # Complexity check
      - name: Code complexity
        run: npx complexity-report

      # PR size check
      - name: Size check
        uses: actions/github-script@v7
        with:
          script: |
            const size = context.payload.pull_request.additions +
                        context.payload.pull_request.deletions
            if (size > 500) {
              core.setFailed('PR too large. Please split into smaller PRs.')
            }

      # Auto-label
      - name: Label PR
        uses: actions/labeler@v4
```

**Tiered Contributor Permissions:**
```markdown
# CONTRIBUTING.md

## Contributor Levels

### Level 1: New Contributor
- PRs require 2 maintainer approvals
- Must pass all automated checks
- Expect 1-2 week review time
- Focus: Bug fixes, docs, tests

### Level 2: Regular Contributor (5+ merged PRs)
- PRs require 1 maintainer approval
- Can self-merge after approval
- Expected review: 3-5 days
- Can work on: Features, refactoring

### Level 3: Trusted Contributor (20+ merged PRs)
- Can approve other PRs
- Can self-merge after 1 approval from another trusted contributor
- Expected review: 1-2 days
- Can work on: Anything

### Level 4: Maintainer
- Can merge without approval for small changes
- Can grant contributor levels
- Expected to review 5+ PRs per week
```

**Community Review Incentives:**
```markdown
## Review Credits

To encourage community review:

1. **Review to be reviewed**: For every PR you review, your next PR gets priority
2. **Review badges**: Top reviewers get badges on profile
3. **Fast track**: Level 3 contributors get <24h review SLA
4. **Pair review**: Offer to pair on complex PRs (30min video call)
```

**Automated PR Triage:**
```typescript
// Bot auto-assigns based on:
// 1. File expertise (past commits to those files)
// 2. Reviewer availability (timezone, recent activity)
// 3. Load balancing (pending reviews)
// 4. Contributor level (new contributors to experienced reviewers)

async function triagePR(pr: PullRequest) {
  const labels = []

  // Auto-label by files
  if (pr.files.some(f => f.endsWith('.md'))) {
    labels.push('documentation')
  }
  if (pr.files.some(f => f.includes('test'))) {
    labels.push('tests')
  }

  // Auto-label by size
  const size = pr.additions + pr.deletions
  if (size < 50) labels.push('size: XS')
  else if (size < 200) labels.push('size: S')
  else if (size < 500) labels.push('size: M')
  else labels.push('size: L')

  // Auto-assign reviewers
  const contributorLevel = await getContributorLevel(pr.author)
  const reviewersNeeded = contributorLevel === 1 ? 2 : 1

  const experts = await findExperts(pr.files)
  const availableExperts = experts.filter(e => isAvailable(e))

  const reviewers = availableExperts
    .sort((a, b) => a.pendingReviews - b.pendingReviews)
    .slice(0, reviewersNeeded)

  await assignReviewers(pr, reviewers)
  await addLabels(pr, labels)

  // Comment with guidance
  await addComment(pr, `
    Thanks for your contribution!

    This PR has been labeled as ${labels.join(', ')}.
    ${reviewersNeeded} approvals needed.
    Estimated review time: ${estimateReviewTime(contributorLevel)} days.

    While you wait:
    - ✅ Ensure all CI checks pass
    - ✅ Add tests if not present
    - ✅ Update documentation if needed
    - 💡 Consider reviewing another PR (gets yours reviewed faster!)
  `)
}
```

**Results:**
- 40% faster review times
- More distributed review load
- Contributors incentivized to review
- Maintainer burnout reduced
- Quality maintained through automation

---

### 4. Mobile App Team (iOS/Android)

#### Context
- Platform-specific code (Swift, Kotlin)
- Long build times (5-10 min)
- App store review adds 1-2 day delay
- Need to be very careful (can't hotfix easily)
- Small team (3-5 per platform)

#### Problems
- Can't iterate as fast as web teams
- Mistakes expensive (app store review)
- Build times slow down review
- Platform knowledge siloed

#### Solution: Extra Careful Review + Extensive Testing

**Pre-Review Checklist:**
```markdown
## Pre-Submission Checklist (Required)

### Testing
- [ ] Tested on iPhone (latest)
- [ ] Tested on iPhone (oldest supported)
- [ ] Tested on iPad
- [ ] Tested in portrait and landscape
- [ ] Tested with VoiceOver (accessibility)
- [ ] Tested with airplane mode
- [ ] Tested with poor network (Network Link Conditioner)
- [ ] Tested memory usage (Instruments)

### Code Quality
- [ ] No force unwraps (!)
- [ ] Error handling for all network calls
- [ ] Localization strings added
- [ ] Dark mode tested
- [ ] No hardcoded values
- [ ] Backward compatible (or migration plan)

### Performance
- [ ] No blocking main thread
- [ ] Images optimized
- [ ] Network requests minimized
- [ ] Cache strategy implemented

### App Store
- [ ] No private API usage
- [ ] Privacy manifest updated (if needed)
- [ ] No tracking without consent
```

**Staged Rollout Process:**
```
Week 1: Internal testing (TestFlight internal track)
Week 2: Beta testing (TestFlight external track, 100 users)
Week 3: Gradual rollout (5% → 25% → 50%)
Week 4: Full rollout (100%)
```

**Review Process:**
```
1. Author self-review (video recording of app usage)
2. Automated checks (lint, tests, build)
3. Peer review (code)
4. QA review (manual testing on devices)
5. Platform lead approval (iOS/Android lead)
6. Merge to main
7. Internal TestFlight build
8. Team dogfooding (1-2 days)
9. Beta TestFlight build
10. Monitor crash reports
11. Submit to App Store
12. Gradual rollout
```

**Video Review:**
```markdown
## Video Walkthrough (Required for UI changes)

Record a 2-3 minute video showing:
1. The problem/before state
2. Your changes in action
3. Edge cases (empty states, errors, loading)
4. Different screen sizes

Upload to: [internal video hosting]

This helps reviewers understand without needing to build locally.
```

**Simulation Before Real Devices:**
```bash
# Automated testing on simulators first
fastlane test

# If passes, then manual testing on real devices
# If fails, fix before review
```

**Results:**
- Fewer production bugs
- Higher app store ratings
- Slower but more deliberate pace (acceptable for mobile)
- Strong safety culture

---

### 5. Infrastructure/Platform Team (Supporting Other Teams)

#### Context
- Changes affect all product teams
- High blast radius
- Changes rarely visible to users directly
- Other teams depend on their work
- Breaking changes very expensive

#### Problems
- Must maintain backward compatibility
- Hard to test impact on all teams
- Review requires deep expertise
- Changes block other teams

#### Solution: Contract-First Development + Extensive Communication

**RFC Process for Large Changes:**
```markdown
# RFC Template

## RFC-###: [Title]

**Status**: Draft | Review | Accepted | Implemented
**Author**: [Name]
**Created**: YYYY-MM-DD
**Updated**: YYYY-MM-DD

## Summary
One paragraph explaining the change.

## Motivation
Why are we doing this? What problem does it solve?

## Detailed Design
How will this work? Include:
- API changes
- Migration path
- Backward compatibility strategy
- Rollout plan

## Drawbacks
What are the costs/risks?

## Alternatives
What other approaches were considered?

## Impact Analysis
Which teams/services are affected?

## Migration Guide
How will teams adopt this change?

## Timeline
- RFC Review: 1 week
- Implementation: 2 weeks
- Migration Period: 4 weeks
- Deprecation: 8 weeks

## Open Questions
What's still unclear?
```

**Pre-Announcement:**
```markdown
# Before creating PR

1. Write RFC
2. Share in #platform-announcements
3. Get feedback from affected teams
4. Present at platform sync meeting
5. Incorporate feedback into RFC
6. Get RFC approved
7. THEN create PR

This ensures no surprises during code review.
```

**Staged Rollout for Infrastructure:**
```
1. Implement behind feature flag
2. Deploy to staging
3. Migrate one internal service (canary)
4. Monitor for 1 week
5. Migrate 3 more services
6. Monitor for 1 week
7. Announce migration window
8. Teams migrate on their schedule (4 week window)
9. Mark old API deprecated
10. Remove old API (8 weeks later)
```

**Review Requirements:**
```yaml
# CODEOWNERS for platform team
/platform/core/ @platform-team @cto
/platform/api/ @platform-team @api-guild @architect
/platform/database/ @platform-team @database-team @cto

# Require:
# - 2 platform team approvals
# - 1 architect approval
# - 1 approval from affected team (if breaking change)
```

**Communication Plan:**
```markdown
# For each infrastructure PR

## Before Merge
- [ ] RFC approved
- [ ] Announcement in #platform-announcements
- [ ] Docs updated
- [ ] Migration guide written
- [ ] Affected teams notified directly (Slack DM)

## After Merge
- [ ] Deploy to staging
- [ ] Smoke test
- [ ] Announce in #platform-announcements
- [ ] Office hours scheduled (for questions)
- [ ] Monitor error rates
- [ ] Follow-up with affected teams (1 week later)
```

**Results:**
- No surprise breaking changes
- Teams have time to prepare
- Better designs (RFC process surfaces issues early)
- Reduced firefighting
- Trust between teams

---

### 6. Security Team (High-Risk Changes)

#### Context
- Every change could introduce vulnerability
- Mistakes have severe consequences
- Compliance requirements (SOC2, ISO 27001)
- Small team, high expectations

#### Problems
- Review is bottleneck
- Can't compromise on quality
- Need to be thorough but fast
- Limited security expertise in product teams

#### Solution: Security-as-Code + Education

**Automated Security Review:**
```yaml
# .github/workflows/security.yml
name: Security Review

on: pull_request

jobs:
  security-scan:
    runs-on: ubuntu-latest
    steps:
      # SAST (Static Application Security Testing)
      - name: Semgrep
        uses: returntocorp/semgrep-action@v1

      # Dependency scanning
      - name: Snyk
        uses: snyk/actions/node@master

      # Secret scanning
      - name: TruffleHog
        uses: trufflesecurity/trufflehog@main

      # IaC scanning
      - name: Checkov
        uses: bridgecrewio/checkov-action@master

      # Container scanning (if applicable)
      - name: Trivy
        uses: aquasecurity/trivy-action@master

      # Custom security checks
      - name: Custom checks
        run: |
          # Check for common mistakes
          ! grep -r "password.*=.*['\"]" src/
          ! grep -r "api_key.*=.*['\"]" src/
          ! grep -r "eval(" src/
          ! grep -r "innerHTML" src/
```

**Security Tiers:**
```python
# Auto-approve if:
def is_auto_approvable(pr):
    return (
        pr.author in TRUSTED_DEVELOPERS and
        pr.lines_changed < 50 and
        not touches_security_sensitive_files(pr) and
        all_security_scans_passed(pr)
    )

# Quick security review if:
def needs_quick_review(pr):
    return (
        pr.lines_changed < 200 and
        not introduces_new_auth_logic(pr) and
        all_security_scans_passed(pr)
    )

# Full security review if:
def needs_full_review(pr):
    return (
        touches_auth_code(pr) or
        touches_crypto_code(pr) or
        touches_payment_code(pr) or
        adds_new_dependencies(pr) or
        pr.lines_changed > 500
    )
```

**Security Review Checklist:**
```markdown
## Security Review Checklist (Reviewer)

### Input Validation
- [ ] All user input validated
- [ ] Parameterized queries (no SQL injection)
- [ ] No eval() or similar
- [ ] File uploads validated (type, size)

### Authentication & Authorization
- [ ] Auth required where needed
- [ ] Proper permission checks
- [ ] No auth bypass possible
- [ ] Session management secure

### Data Protection
- [ ] Sensitive data encrypted at rest
- [ ] Sensitive data encrypted in transit (HTTPS)
- [ ] No sensitive data in logs
- [ ] PII handling compliant (GDPR, etc.)

### Cryptography
- [ ] Strong algorithms used (no MD5, SHA1)
- [ ] Proper key management
- [ ] No hardcoded secrets
- [ ] Random number generation secure

### API Security
- [ ] Rate limiting implemented
- [ ] CORS configured properly
- [ ] No sensitive data in URLs
- [ ] API tokens not exposed

### Dependencies
- [ ] No known vulnerabilities (Snyk passed)
- [ ] Legitimate packages (no typosquatting)
- [ ] License compliance

### Infrastructure
- [ ] Principle of least privilege
- [ ] Secrets in vault (not env vars)
- [ ] Network segmentation proper
```

**Security Champions Program:**
```markdown
# Security Champions (in each product team)

## Responsibilities
1. First-line security review for their team
2. Attend monthly security training
3. Evangelize security best practices
4. Escalate to security team when needed

## Benefits
- Distributed security expertise
- Faster review (don't need security team for every PR)
- Better security culture

## Process
1. Product team PR created
2. Security champion reviews first
3. If they approve, no security team review needed (for low/medium risk)
4. If uncertain, escalate to security team
```

**Education Over Gatekeeping:**
```markdown
# Security Team Philosophy

Instead of just saying "no", we:

1. **Explain why**: Every security comment includes reasoning
2. **Provide alternative**: Suggest secure implementation
3. **Link to docs**: Point to security guidelines
4. **Offer pairing**: 30min session to implement securely
5. **Create tooling**: Make secure path easy path

Example comment:
❌ Bad: "This is insecure"
✅ Good: "This could allow SQL injection because user input is concatenated into query. Use parameterized queries instead: `db.query('SELECT * FROM users WHERE id = ?', [userId])`. See: [docs link]. Happy to pair on this if helpful!"
```

**Results:**
- Security team not bottleneck
- Product teams learn security
- Automated checks catch 80% of issues
- Security team focuses on hard problems
- Better security culture

---

## Cross-Cutting Patterns

### Pattern 1: Review Time Blocks

**Problem:** Reviews happen ad-hoc, interrupting flow

**Solution:** Scheduled review time

```markdown
# Team Agreement

## Individual
- 9:30-10:00am: Review queue
- 2:00-2:30pm: Review queue

## Team
- Tuesday 2pm: Mob review session
  - Review oldest/largest PRs together
  - Knowledge sharing
  - Mentoring juniors
```

---

### Pattern 2: Review Rotation

**Problem:** Same people always review

**Solution:** Rotate responsibility

```markdown
# Weekly Rotation

## On-Call Reviewer (rotates weekly)
Responsibilities:
- Respond to all PRs within 2 hours
- Triage (assign to experts if needed)
- Approve simple PRs
- Escalate complex PRs

This week: Alice
Next week: Bob
Schedule: [link to rotation calendar]
```

---

### Pattern 3: Office Hours

**Problem:** Async review too slow for urgent/complex changes

**Solution:** Sync review sessions

```markdown
# Review Office Hours

## Daily: 3:00-3:30pm
- Drop in with your PR
- Live review
- Immediate feedback
- Perfect for:
  - Urgent fixes
  - Complex changes
  - Learning opportunities

## How to use
1. Book 10min slot: [calendar link]
2. Share PR link + context
3. Screen share walkthrough
4. Get approval on the spot
```

---

### Pattern 4: Async Stand-up

**Problem:** Team doesn't know what others are working on

**Solution:** Automated daily summary

```markdown
# Daily Summary Bot (in Slack)

Every morning at 9am:

📊 Yesterday's Activity
- 12 PRs merged
- 5 PRs opened
- 8 PRs waiting for review

🚀 Shipped
- @alice: Fixed checkout bug (#123)
- @bob: Added search feature (#124)
- @carol: Refactored auth (#125)

⏳ Needs Review (oldest first)
- PR #120: Database migration (3 days old) - @dave
- PR #119: API refactor (2 days old) - @eve

🔥 Urgent
- PR #126: Production hotfix - needs approval ASAP

[View all PRs] [Claim a review]
```

---

### Pattern 5: Review Metrics Dashboard

**Problem:** No visibility into review health

**Solution:** Real-time dashboard

```markdown
# Review Health Dashboard

## This Week
- Cycle time (P50): 4.2h ✅ (target: <6h)
- Cycle time (P90): 18h ⚠️ (target: <24h)
- PRs merged: 47 ✅ (up from 42 last week)
- Auto-merge rate: 23% ✅ (target: >20%)

## Blockers
- 2 PRs waiting >48h (need attention)
- 1 PR blocked on security review

## Review Load
- Alice: 3 pending
- Bob: 7 pending ⚠️ (consider reassigning)
- Carol: 1 pending

## Trends (Last 4 Weeks)
[Chart showing improving cycle time]

[Detailed view] [Export data]
```

---

## Measuring Success

### Leading Indicators (Predict Future Problems)
- **PR age**: How long are PRs sitting?
- **Review queue depth**: How many PRs per reviewer?
- **SLA compliance**: % of PRs reviewed within SLA
- **PR size**: Are PRs getting bigger?

### Lagging Indicators (Show Past Performance)
- **Cycle time**: PR creation to merge
- **Deploy frequency**: How often do you ship?
- **Bug escape rate**: Production bugs per merge
- **Revert rate**: How often do you rollback?

### Qualitative Indicators
- **Developer satisfaction**: Survey quarterly
- **Review quality**: Are reviews helpful or just rubber stamps?
- **Learning**: Are juniors improving through review?
- **Culture**: Is review seen as collaborative or adversarial?

---

## Summary: Choosing Your Pattern

| Team Type | Recommended Pattern | Key Tools | Expected Impact |
|-----------|-------------------|-----------|-----------------|
| **Fast Startup** | Ship/Show/Ask | Feature flags, fast rollback | 5-10x faster shipping |
| **Enterprise** | Tiered review + ownership | Automated risk scoring, CODEOWNERS | 40% faster cycle time |
| **Open Source** | Bot-first + community review | GitHub Actions, contributor levels | 2x more PRs reviewed |
| **Mobile** | Extra careful + staged rollout | TestFlight, extensive checklist | 50% fewer production bugs |
| **Platform** | RFC + staged migration | Feature flags, migration guides | Zero surprise breaking changes |
| **Security** | Automated + champions | SAST/DAST tools, security champions | 70% less security team bottleneck |

### Universal Principles

Regardless of team type:
1. **Automate the boring stuff** (format, lint, security scans)
2. **Right-size review** (not everything needs deep review)
3. **Set clear SLAs** (everyone knows expectations)
4. **Make review visible** (dashboards, Slack updates)
5. **Iterate continuously** (retrospect, improve process)

The best review process is one that **doesn't feel like a process**—it just works.
