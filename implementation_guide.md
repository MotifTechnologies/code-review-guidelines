# Code Review Process: Implementation Guide

## Quick Start Templates & Configurations

This guide provides copy-paste configurations and templates to implement modern code review practices immediately.

---

## 1. PR Templates

### Standard PR Template

Create `.github/PULL_REQUEST_TEMPLATE.md`:

```markdown
## What Changed
<!-- Brief description of what this PR does -->

## Why
<!-- Why is this change needed? Link to issue/ticket -->

## How to Test
<!-- Steps to verify this works -->
1.
2.
3.

## Screenshots/Demo
<!-- For UI changes, add before/after screenshots -->

## Checklist
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] No breaking changes (or migration plan documented)
- [ ] Performance impact considered
- [ ] Security impact considered

## Review Tier
<!-- Select one: -->
- [ ] Auto-merge (docs/tests only)
- [ ] Quick review (small, low-risk)
- [ ] Standard review (default)
- [ ] Full review (high-risk, API changes)

## Related PRs
<!-- If part of a stack, list dependencies -->
- Depends on: #
- Required for: #
```

### Ship/Show/Ask Template

Create `.github/PULL_REQUEST_TEMPLATE/ship_show_ask.md`:

```markdown
## Change Type
<!-- Choose ONE -->

### 🚢 SHIP (Merge Now, Notify Later)
- [ ] This is a trivial change (typo, obvious fix)
- [ ] I'm confident this is correct
- [ ] Easy to revert if needed
- [ ] **I will merge this immediately after CI passes**

### 👀 SHOW (Merge Soon, Review Async)
- [ ] This is low-risk but I want feedback
- [ ] **I will merge within 4 hours, review async**
- [ ] Follow-up PR if changes needed

### 🙋 ASK (Traditional Review)
- [ ] This is high-risk or I need guidance
- [ ] **I will wait for approval before merging**

---

## What Changed


## Why


## Testing
```

---

## 2. GitHub Actions Workflows

### Auto-Format on PR

`.github/workflows/auto-format.yml`:

```yaml
name: Auto-format Code

on:
  pull_request:
    branches: [main]

jobs:
  format:
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write

    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ github.head_ref }}
          token: ${{ secrets.GITHUB_TOKEN }}

      - name: Set up Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Install dependencies
        run: npm ci

      - name: Run Prettier
        run: npm run format

      - name: Commit changes
        uses: stefanzweifel/git-auto-commit-action@v5
        with:
          commit_message: "style: auto-format code"
          commit_user_name: "github-actions[bot]"
          commit_user_email: "github-actions[bot]@users.noreply.github.com"
```

### Review SLA Reminder

`.github/workflows/review-sla.yml`:

```yaml
name: Review SLA Reminder

on:
  schedule:
    - cron: '0 */2 * * *'  # Every 2 hours
  workflow_dispatch:

jobs:
  check-sla:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Check PRs waiting for review
        uses: actions/github-script@v7
        with:
          script: |
            const QUICK_REVIEW_SLA = 4 * 60 * 60 * 1000; // 4 hours
            const STANDARD_REVIEW_SLA = 24 * 60 * 60 * 1000; // 24 hours

            const { data: pulls } = await github.rest.pulls.list({
              owner: context.repo.owner,
              repo: context.repo.repo,
              state: 'open',
              sort: 'created',
              direction: 'asc'
            });

            const now = Date.now();

            for (const pr of pulls) {
              const createdAt = new Date(pr.created_at).getTime();
              const age = now - createdAt;

              // Get reviews
              const { data: reviews } = await github.rest.pulls.listReviews({
                owner: context.repo.owner,
                repo: context.repo.repo,
                pull_number: pr.number
              });

              if (reviews.length === 0) {
                // Check labels for tier
                const labels = pr.labels.map(l => l.name);
                const isQuickReview = labels.includes('quick-review');
                const sla = isQuickReview ? QUICK_REVIEW_SLA : STANDARD_REVIEW_SLA;

                if (age > sla) {
                  // Add comment and label
                  await github.rest.issues.addLabels({
                    owner: context.repo.owner,
                    repo: context.repo.repo,
                    issue_number: pr.number,
                    labels: ['review-overdue']
                  });

                  await github.rest.issues.createComment({
                    owner: context.repo.owner,
                    repo: context.repo.repo,
                    issue_number: pr.number,
                    body: `⚠️ This PR has been waiting for review for ${Math.floor(age / (60 * 60 * 1000))} hours, which exceeds our SLA. cc @${context.repo.owner}/reviewers`
                  });
                }
              }
            }
```

### PR Size Check

`.github/workflows/pr-size.yml`:

```yaml
name: PR Size Check

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  size-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/github-script@v7
        with:
          script: |
            const { data: pr } = await github.rest.pulls.get({
              owner: context.repo.owner,
              repo: context.repo.repo,
              pull_number: context.payload.pull_request.number
            });

            const additions = pr.additions;
            const deletions = pr.deletions;
            const total = additions + deletions;

            let label = '';
            let message = '';

            if (total < 100) {
              label = 'size/XS';
              message = '✅ Great! This PR is small and easy to review.';
            } else if (total < 400) {
              label = 'size/S';
              message = '✅ Good size for review.';
            } else if (total < 1000) {
              label = 'size/M';
              message = '⚠️ This PR is getting large. Consider splitting if possible.';
            } else if (total < 2000) {
              label = 'size/L';
              message = '⚠️ Large PR. Please consider breaking this into smaller PRs for easier review.';
            } else {
              label = 'size/XL';
              message = '🚨 Very large PR! This will be difficult to review thoroughly. Please break into smaller PRs.';
            }

            // Add label
            await github.rest.issues.addLabels({
              owner: context.repo.owner,
              repo: context.repo.repo,
              issue_number: context.payload.pull_request.number,
              labels: [label]
            });

            // Add comment
            await github.rest.issues.createComment({
              owner: context.repo.owner,
              repo: context.repo.repo,
              issue_number: context.payload.pull_request.number,
              body: `${message}\n\nStats: +${additions} -${deletions} (${total} total changes)`
            });
```

---

## 3. Danger Configuration

`dangerfile.ts`:

```typescript
import { danger, warn, fail, message, markdown } from 'danger'

// Configuration
const MAX_PR_SIZE = 400
const MIN_DESCRIPTION_LENGTH = 20
const REQUIRED_SECTIONS = ['## What', '## Why', '## Testing']

// Check PR description
const prBody = danger.github.pr.body || ''
if (prBody.length < MIN_DESCRIPTION_LENGTH) {
  fail('Please add a meaningful description to your PR.')
}

// Check for required sections
const missingSections = REQUIRED_SECTIONS.filter(section =>
  !prBody.includes(section)
)
if (missingSections.length > 0) {
  warn(`PR description is missing: ${missingSections.join(', ')}`)
}

// Check PR size
const additions = danger.github.pr.additions
const deletions = danger.github.pr.deletions
const totalChanges = additions + deletions

if (totalChanges > MAX_PR_SIZE) {
  warn(
    `🚨 Big PR detected (${totalChanges} changes). ` +
    `Consider breaking this into smaller PRs (target: <${MAX_PR_SIZE} lines).`
  )
}

// Check for test changes
const modifiedFiles = danger.git.modified_files
const createdFiles = danger.git.created_files
const allFiles = [...modifiedFiles, ...createdFiles]

const hasSourceChanges = allFiles.some(f =>
  f.match(/^src\/.*\.(ts|tsx|js|jsx)$/) && !f.match(/\.test\.|\.spec\./)
)
const hasTestChanges = allFiles.some(f =>
  f.match(/\.(test|spec)\.(ts|tsx|js|jsx)$/)
)

if (hasSourceChanges && !hasTestChanges) {
  warn(
    '⚠️ This PR modifies source code but no tests were added/updated. ' +
    'Consider adding tests to verify the changes.'
  )
}

// Check for documentation updates
const hasDocChanges = allFiles.some(f => f.match(/\.(md|mdx)$/))
const hasSignificantChanges = totalChanges > 200

if (hasSignificantChanges && !hasDocChanges) {
  message(
    '📝 This is a significant change. Consider updating documentation if needed.'
  )
}

// Check for breaking changes
const hasBreakingChanges =
  prBody.toLowerCase().includes('breaking') ||
  prBody.toLowerCase().includes('breaking change')

if (hasBreakingChanges) {
  warn('🚨 This PR contains breaking changes. Ensure migration guide is included.')
}

// Suggest reviewers based on files changed
const filePatterns = [
  { pattern: /^src\/auth\//, team: 'security-team', label: 'security-review' },
  { pattern: /^src\/api\//, team: 'api-team', label: 'api-review' },
  { pattern: /^src\/ui\//, team: 'frontend-team', label: 'ui-review' },
  { pattern: /\.sql$|migrations\//, team: 'database-team', label: 'db-review' },
]

for (const { pattern, team, label } of filePatterns) {
  if (allFiles.some(f => pattern.test(f))) {
    message(`🔍 Changes detected that should be reviewed by @${team}`)
    // Automatically add label
    // (requires GitHub token with write permissions)
  }
}

// Check for TODOs
const diffContent = danger.git.diff || ''
const todoMatches = diffContent.match(/TODO|FIXME|XXX/g)

if (todoMatches && todoMatches.length > 0) {
  message(
    `ℹ️ This PR adds ${todoMatches.length} TODO/FIXME comments. ` +
    `Consider creating follow-up issues for tracking.`
  )
}

// Performance check for large loops or queries
const hasPotentialPerformanceIssue = diffContent.match(
  /for.*for.*for|\.map\(.*\.map\(.*\.map\(/
)

if (hasPotentialPerformanceIssue) {
  warn(
    '⚠️ Detected nested loops/maps. Please verify performance impact, ' +
    'especially with large datasets.'
  )
}

// Security patterns
const securityPatterns = [
  { pattern: /eval\(/, message: 'Use of eval() detected - security risk!' },
  { pattern: /innerHTML/, message: 'Use of innerHTML - potential XSS risk' },
  { pattern: /password.*=.*['"]\w/, message: 'Potential hardcoded password' },
  { pattern: /api[_-]?key.*=.*['"]\w/, message: 'Potential hardcoded API key' },
]

for (const { pattern, message: msg } of securityPatterns) {
  if (pattern.test(diffContent)) {
    fail(`🚨 Security issue: ${msg}`)
  }
}

// Generate summary
const summary = `
## PR Summary
- **Size**: ${totalChanges} lines (+${additions} -${deletions})
- **Files changed**: ${allFiles.length}
- **Tests**: ${hasTestChanges ? '✅' : '❌'}
- **Docs**: ${hasDocChanges ? '✅' : 'ℹ️'}
${hasBreakingChanges ? '- **⚠️ Contains breaking changes**' : ''}
`

markdown(summary)
```

---

## 4. Auto-Merge Configuration

### Mergify

`.mergify.yml`:

```yaml
pull_request_rules:
  # Auto-merge docs changes
  - name: Auto-merge docs updates
    conditions:
      - author~=^(team-member-1|team-member-2)$
      - files~=^docs/
      - check-success=CI
      - "#approved-reviews-by>=1"
      - label!=do-not-merge
    actions:
      merge:
        method: squash
        commit_message: title+body
      delete_head_branch: {}
      label:
        add: [auto-merged]

  # Auto-merge dependency updates
  - name: Auto-merge Dependabot (patch)
    conditions:
      - author=dependabot[bot]
      - check-success=CI
      - title~=^(build|chore)\(deps\): bump .* from .* to .*\.\d+$
    actions:
      merge:
        method: squash
      delete_head_branch: {}

  # Auto-merge tests-only changes
  - name: Auto-merge test additions
    conditions:
      - files~=^tests?/
      - -files~=^(?!tests?/)
      - check-success=CI
      - "#approved-reviews-by>=1"
    actions:
      merge:
        method: squash
      delete_head_branch: {}

  # Quick review label for small PRs
  - name: Label small PRs for quick review
    conditions:
      - "#files-changed<=5"
      - "+changes-requested-reviews-by=0"
      - "changes<=200"
    actions:
      label:
        add: [quick-review]

  # Request reviews for large PRs
  - name: Request multiple reviews for large PRs
    conditions:
      - changes>=1000
    actions:
      label:
        add: [large-pr, needs-architecture-review]
      request_reviews:
        teams:
          - tech-leads

  # Auto-label by file type
  - name: Label frontend changes
    conditions:
      - files~=^src/.*\.(tsx|jsx|css|scss)$
    actions:
      label:
        add: [frontend]

  - name: Label backend changes
    conditions:
      - files~=^src/.*/api/.*\.ts$
    actions:
      label:
        add: [backend, needs-api-review]

  - name: Label database changes
    conditions:
      - files~=migrations/|\.sql$
    actions:
      label:
        add: [database, needs-db-review]
```

### Kodiak

`.kodiak.toml`:

```toml
version = 1

[merge]
# Auto-merge PRs when conditions are met
automerge_label = "automerge"
method = "squash"
delete_branch_on_merge = true
optimistic_updates = true
prioritize_ready_to_merge = true

# Merge message
[merge.message]
title = "pull_request_title"
body = "pull_request_body"
include_pr_number = true
strip_html_comments = true

# Auto-approve certain PRs
[approve]
auto_approve_usernames = ["dependabot"]
auto_approve_labels = ["auto-approve"]

# Update branch automatically
[update]
always = true
require_automerge_label = false
```

---

## 5. Code Owners

`.github/CODEOWNERS`:

```
# Default reviewers
* @your-org/developers

# Frontend
/src/ui/ @your-org/frontend-team
/src/components/ @your-org/frontend-team
*.css @your-org/frontend-team
*.scss @your-org/frontend-team

# Backend
/src/api/ @your-org/backend-team
/src/services/ @your-org/backend-team

# Database
/migrations/ @your-org/database-team @your-org/backend-lead
*.sql @your-org/database-team

# Infrastructure
/docker/ @your-org/devops
/kubernetes/ @your-org/devops
/.github/workflows/ @your-org/devops
/terraform/ @your-org/devops

# Security-sensitive
/src/auth/ @your-org/security-team
/src/crypto/ @your-org/security-team

# Documentation
/docs/ @your-org/tech-writers
*.md @your-org/tech-writers

# Config files
package.json @your-org/tech-leads
tsconfig.json @your-org/tech-leads
```

---

## 6. Feature Flag Configuration

### LaunchDarkly Integration

```typescript
// src/lib/feature-flags.ts
import * as LaunchDarkly from 'launchdarkly-node-server-sdk'

const client = LaunchDarkly.init(process.env.LAUNCHDARKLY_SDK_KEY!)

export async function isFeatureEnabled(
  flagKey: string,
  user: { id: string; email?: string; customAttributes?: Record<string, any> }
): Promise<boolean> {
  await client.waitForInitialization()

  return client.variation(flagKey, {
    key: user.id,
    email: user.email,
    custom: user.customAttributes
  }, false) // Default to false
}

export async function getFeatureVariation<T>(
  flagKey: string,
  user: { id: string; email?: string },
  defaultValue: T
): Promise<T> {
  await client.waitForInitialization()

  return client.variation(flagKey, { key: user.id, email: user.email }, defaultValue)
}
```

### Simple In-House Feature Flags

```typescript
// src/lib/simple-flags.ts
interface FeatureFlag {
  name: string
  enabled: boolean
  rolloutPercentage?: number
  allowedUsers?: string[]
  allowedEmails?: string[]
}

const flags: FeatureFlag[] = [
  {
    name: 'new-checkout-flow',
    enabled: true,
    rolloutPercentage: 10, // 10% of users
  },
  {
    name: 'experimental-dashboard',
    enabled: true,
    allowedUsers: ['user-123', 'user-456'], // Beta testers
  },
  {
    name: 'new-api-version',
    enabled: false, // Kill switch
  },
]

export function isFeatureEnabled(
  flagName: string,
  userId?: string,
  userEmail?: string
): boolean {
  const flag = flags.find(f => f.name === flagName)
  if (!flag || !flag.enabled) return false

  // Check allowed users
  if (flag.allowedUsers && userId) {
    return flag.allowedUsers.includes(userId)
  }

  // Check allowed emails
  if (flag.allowedEmails && userEmail) {
    return flag.allowedEmails.includes(userEmail)
  }

  // Check rollout percentage
  if (flag.rolloutPercentage && userId) {
    const hash = hashString(userId)
    return (hash % 100) < flag.rolloutPercentage
  }

  return true
}

function hashString(str: string): number {
  let hash = 0
  for (let i = 0; i < str.length; i++) {
    const char = str.charCodeAt(i)
    hash = ((hash << 5) - hash) + char
    hash = hash & hash // Convert to 32-bit integer
  }
  return Math.abs(hash)
}
```

### Usage in Code

```typescript
// Good: Feature flag at component boundary
export function CheckoutPage() {
  const user = useCurrentUser()
  const useNewFlow = isFeatureEnabled('new-checkout-flow', user.id)

  if (useNewFlow) {
    return <NewCheckoutFlow />
  }

  return <LegacyCheckoutFlow />
}

// Bad: Feature flag scattered throughout
export function CheckoutPage() {
  // ... lots of code ...
  if (isFeatureEnabled('step-2-redesign')) {
    // new logic
  } else {
    // old logic
  }
  // ... more code ...
}
```

---

## 7. Review Rotation Script

`scripts/assign-reviewer.ts`:

```typescript
#!/usr/bin/env ts-node
import { Octokit } from '@octokit/rest'

const octokit = new Octokit({ auth: process.env.GITHUB_TOKEN })

interface Reviewer {
  username: string
  pendingReviews: number
  expertise: string[]
  timezone: string
  available: boolean
}

async function assignReviewer(prNumber: number) {
  const { data: pr } = await octokit.pulls.get({
    owner: 'your-org',
    repo: 'your-repo',
    pull_number: prNumber,
  })

  const changedFiles = await octokit.pulls.listFiles({
    owner: 'your-org',
    repo: 'your-repo',
    pull_number: prNumber,
  })

  const fileNames = changedFiles.data.map(f => f.filename)

  // Get eligible reviewers
  const reviewers: Reviewer[] = await getEligibleReviewers()

  // Score reviewers
  const scoredReviewers = reviewers.map(reviewer => {
    let score = 0

    // Prefer reviewers with fewer pending reviews (load balancing)
    score += (10 - reviewer.pendingReviews) * 10

    // Prefer reviewers with relevant expertise
    const hasExpertise = fileNames.some(file =>
      reviewer.expertise.some(exp => file.includes(exp))
    )
    score += hasExpertise ? 50 : 0

    // Prefer available reviewers
    score += reviewer.available ? 20 : 0

    // Timezone bonus (prefer same timezone as author)
    if (reviewer.timezone === getAuthorTimezone(pr.user.login)) {
      score += 15
    }

    return { reviewer, score }
  })

  // Sort by score
  scoredReviewers.sort((a, b) => b.score - a.score)

  // Assign top 2 reviewers
  const assignees = scoredReviewers.slice(0, 2).map(s => s.reviewer.username)

  await octokit.pulls.requestReviewers({
    owner: 'your-org',
    repo: 'your-repo',
    pull_number: prNumber,
    reviewers: assignees,
  })

  console.log(`Assigned reviewers: ${assignees.join(', ')}`)
}

async function getEligibleReviewers(): Promise<Reviewer[]> {
  // Fetch from your team config
  return [
    {
      username: 'alice',
      pendingReviews: 2,
      expertise: ['frontend', 'ui'],
      timezone: 'America/New_York',
      available: true,
    },
    {
      username: 'bob',
      pendingReviews: 5,
      expertise: ['backend', 'api'],
      timezone: 'America/Los_Angeles',
      available: true,
    },
    // ... more reviewers
  ]
}

function getAuthorTimezone(username: string): string {
  // Fetch from your team config
  return 'America/New_York'
}

// Run
const prNumber = parseInt(process.argv[2])
assignReviewer(prNumber)
```

---

## 8. Metrics Dashboard Query

### SQL Query for Review Metrics

```sql
-- Review cycle time (PR creation to merge)
WITH pr_metrics AS (
  SELECT
    pr.id,
    pr.number,
    pr.created_at,
    pr.merged_at,
    pr.additions + pr.deletions AS size,
    EXTRACT(EPOCH FROM (pr.merged_at - pr.created_at)) / 3600 AS cycle_time_hours,
    (
      SELECT MIN(created_at)
      FROM reviews
      WHERE reviews.pr_id = pr.id
    ) AS first_review_at,
    EXTRACT(EPOCH FROM (
      (SELECT MIN(created_at) FROM reviews WHERE reviews.pr_id = pr.id) - pr.created_at
    )) / 3600 AS time_to_first_review_hours
  FROM pull_requests pr
  WHERE pr.merged_at IS NOT NULL
    AND pr.created_at >= NOW() - INTERVAL '7 days'
)
SELECT
  PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY cycle_time_hours) AS p50_cycle_time,
  PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY cycle_time_hours) AS p90_cycle_time,
  PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY cycle_time_hours) AS p99_cycle_time,
  PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY time_to_first_review_hours) AS p50_first_review,
  AVG(size) AS avg_pr_size,
  COUNT(*) AS total_prs,
  COUNT(*) FILTER (WHERE size <= 100) AS prs_small,
  COUNT(*) FILTER (WHERE size <= 400) AS prs_medium,
  COUNT(*) FILTER (WHERE size > 400) AS prs_large
FROM pr_metrics;

-- Reviewer load distribution
SELECT
  reviewer.username,
  COUNT(*) AS review_count,
  AVG(EXTRACT(EPOCH FROM (reviews.submitted_at - pr.created_at)) / 3600) AS avg_response_time_hours
FROM reviews
JOIN pull_requests pr ON reviews.pr_id = pr.id
JOIN users reviewer ON reviews.reviewer_id = reviewer.id
WHERE reviews.created_at >= NOW() - INTERVAL '7 days'
GROUP BY reviewer.username
ORDER BY review_count DESC;
```

---

## 9. Slack Bot Integration

### Review Notification Bot

```typescript
// src/bots/review-bot.ts
import { WebClient } from '@slack/web-api'
import { Octokit } from '@octokit/rest'

const slack = new WebClient(process.env.SLACK_TOKEN)
const github = new Octokit({ auth: process.env.GITHUB_TOKEN })

export async function notifyNewPR(prNumber: number) {
  const { data: pr } = await github.pulls.get({
    owner: 'your-org',
    repo: 'your-repo',
    pull_number: prNumber,
  })

  const size = pr.additions + pr.deletions
  const sizeLabel = size < 100 ? '🟢 XS' : size < 400 ? '🟡 S' : '🔴 L'
  const tier = pr.labels.some(l => l.name === 'quick-review')
    ? 'Quick Review (4h SLA)'
    : 'Standard Review (24h SLA)'

  await slack.chat.postMessage({
    channel: '#code-review',
    text: `New PR: ${pr.title}`,
    blocks: [
      {
        type: 'section',
        text: {
          type: 'mrkdwn',
          text: `*New PR from <@${pr.user.login}>*\n${pr.title}`,
        },
      },
      {
        type: 'section',
        fields: [
          { type: 'mrkdwn', text: `*Size:* ${sizeLabel} (${size} lines)` },
          { type: 'mrkdwn', text: `*Tier:* ${tier}` },
          { type: 'mrkdwn', text: `*Files:* ${pr.changed_files}` },
          { type: 'mrkdwn', text: `*Reviewers:* ${pr.requested_reviewers.map(r => r.login).join(', ') || 'None'}` },
        ],
      },
      {
        type: 'actions',
        elements: [
          {
            type: 'button',
            text: { type: 'plain_text', text: 'Review on GitHub' },
            url: pr.html_url,
            style: 'primary',
          },
          {
            type: 'button',
            text: { type: 'plain_text', text: 'Claim Review' },
            value: `claim_${prNumber}`,
            action_id: 'claim_review',
          },
        ],
      },
    ],
  })
}

export async function notifyReviewOverdue(prNumber: number) {
  const { data: pr } = await github.pulls.get({
    owner: 'your-org',
    repo: 'your-repo',
    pull_number: prNumber,
  })

  await slack.chat.postMessage({
    channel: '#code-review',
    text: `⚠️ PR #${prNumber} needs review!`,
    blocks: [
      {
        type: 'section',
        text: {
          type: 'mrkdwn',
          text: `⚠️ *PR waiting for review* (SLA exceeded)\n${pr.title}`,
        },
      },
      {
        type: 'section',
        text: {
          type: 'mrkdwn',
          text: `This PR has been waiting for ${calculateWaitTime(pr.created_at)}. Please review ASAP!`,
        },
      },
      {
        type: 'actions',
        elements: [
          {
            type: 'button',
            text: { type: 'plain_text', text: 'Review Now' },
            url: pr.html_url,
            style: 'danger',
          },
        ],
      },
    ],
  })
}

function calculateWaitTime(createdAt: string): string {
  const hours = (Date.now() - new Date(createdAt).getTime()) / (1000 * 60 * 60)
  if (hours < 24) return `${Math.floor(hours)} hours`
  return `${Math.floor(hours / 24)} days`
}
```

---

## 10. Team Review Guidelines Document

`docs/REVIEW_GUIDELINES.md`:

```markdown
# Code Review Guidelines

## Our Philosophy
- **Speed matters**: Fast feedback helps everyone
- **Trust first**: Assume good intent
- **Automate the boring stuff**: Focus on what matters
- **Review is learning**: Not just gatekeeping

## Review Tiers

### Auto-Merge (No Review)
- Documentation changes
- Test additions (no logic changes)
- Dependency bumps (patch versions)
- Formatting/linting fixes

### Quick Review (<4 hour SLA)
- Small bug fixes (<100 lines)
- Low-risk refactoring
- Minor feature additions
- Changes by senior engineers

**What to check:**
- ✅ Does it solve the problem?
- ✅ Any obvious bugs?
- ✅ Tests included?
- ⏭️ Don't nitpick style

### Standard Review (<24 hour SLA)
- Most feature work
- Moderate refactoring
- New components/modules

**What to check:**
- ✅ Correctness
- ✅ Test coverage
- ✅ Documentation
- ✅ Readability
- ⚠️ Performance considerations

### Full Review (2+ approvals)
- API changes
- Security-sensitive code
- Database migrations
- Architecture changes

**What to check:**
- ✅ Everything from standard review
- ✅ Security implications
- ✅ Performance testing
- ✅ Backwards compatibility
- ✅ Migration plan
- ✅ Monitoring/alerting

## How to Write Good Reviews

### Use Conventional Comments

```
suggestion: Consider extracting this into a helper function
This pattern appears in 3 places.

question: Why did you choose Map over Set here?
Just curious about the tradeoff.

nitpick (non-blocking): Extra blank line
Not important, feel free to ignore.

issue (blocking): This will throw if user is null
Need to add null check.

praise: Great test coverage!
Love the edge cases you covered.
```

### Be Specific

❌ "This is confusing"
✅ "The variable name `data` is ambiguous. Consider `userProfiles` or `accountData`"

❌ "Add tests"
✅ "Please add a test for the case where the API returns 404"

### Approve with Nits

Don't block on minor issues:

```
LGTM! 🚀

nitpick: Consider renaming `foo` to `userCache` for clarity
nitpick: Extra whitespace on line 42

Feel free to merge as-is or fix in follow-up PR.
```

### Time-Box Your Review

- **5 minutes**: Quick scan (does it make sense?)
- **15 minutes**: Thorough review (logic, tests, edge cases)
- **30 minutes**: Deep review (architecture, performance)

If you need more time, consider pairing or requesting more context.

## Ship/Show/Ask

### 🚢 Ship
**Merge immediately, notify team**

Use for:
- Trivial fixes (typos, obvious bugs)
- Time-sensitive changes
- Experimental work (with feature flags)

### 👀 Show
**Merge within hours, async review**

Use for:
- Most feature work
- Refactoring
- Changes you're confident in but want feedback

Process:
1. Create PR
2. Merge after CI passes (or within 4 hours)
3. Team reviews asynchronously
4. Address feedback in follow-up PR

### 🙋 Ask
**Wait for approval**

Use for:
- High-risk changes
- Areas where you want guidance
- API contracts
- Database migrations

## Stacked PRs

For large features, create a stack:

```
PR1: Add User model
  ↓
PR2: Add User API
  ↓
PR3: Add User UI
```

Each PR should:
- Be independently valuable
- Be small (<400 lines)
- Have clear dependencies documented

Use Graphite or git-branchless for easy management.

## SLA Expectations

| Tier | First Response | Approval | Merge |
|------|---------------|----------|-------|
| Auto-merge | N/A | N/A | Immediate |
| Quick | 2 hours | 4 hours | 6 hours |
| Standard | 4 hours | 24 hours | 36 hours |
| Full | 8 hours | 48 hours | 72 hours |

**SLA applies during business hours (9am-6pm in your timezone)**

## What If Review is Blocked?

1. **Ping in Slack**: After 4 hours, ping #code-review
2. **Request different reviewer**: Original reviewer might be busy
3. **Pair review**: Schedule 15-min sync review
4. **Escalate**: After 24 hours, ping team lead

## As a PR Author

### Before Creating PR
- ✅ Self-review your changes
- ✅ Run tests locally
- ✅ Add meaningful commit messages
- ✅ Keep PR small (<400 lines)

### PR Description
- What changed
- Why it changed
- How to test
- Screenshots (for UI)
- Related PRs (for stacks)

### During Review
- Respond to comments within 4 hours
- Ask questions if feedback is unclear
- Don't take feedback personally
- Push fixes promptly

### After Approval
- Merge quickly (don't let approved PRs sit)
- Delete branch after merge
- Monitor for issues

## As a Reviewer

### Prioritize Reviews
1. Blocked deployments
2. Quick reviews (<100 lines)
3. Standard reviews
4. Full reviews

### Daily Routine
- **9am**: Review queue (30 min)
- **After lunch**: Review queue (30 min)
- **End of day**: Clear any remaining

### When to Approve
- ✅ Correct logic
- ✅ Tests pass
- ✅ No obvious security issues
- ✅ Maintainable code

### When to Request Changes
- ❌ Breaks existing functionality
- ❌ Security vulnerability
- ❌ Missing critical tests
- ❌ Performance regression

### Trust and Iterate
If in doubt, approve with comments:
- "LGTM, but consider X for next time"
- "Approved. Would love to see Y in a follow-up"

We can always iterate!
```

---

## Summary

This implementation guide provides ready-to-use configurations for:

1. **PR Templates** - Standardize PR descriptions
2. **GitHub Actions** - Automate formatting, size checks, SLA reminders
3. **Danger** - Automated PR feedback
4. **Auto-Merge** - Mergify/Kodiak configurations
5. **Code Owners** - Automatic reviewer assignment
6. **Feature Flags** - Safe trunk-based development
7. **Review Rotation** - Load-balanced reviewer assignment
8. **Metrics** - SQL queries for review health
9. **Slack Integration** - Real-time notifications
10. **Team Guidelines** - Clear review expectations

Start with items 1-3 for immediate impact, then gradually add the rest as your team matures.
