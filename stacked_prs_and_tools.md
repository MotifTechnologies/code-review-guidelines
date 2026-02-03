# Stacked PRs & Trunk-Based Development: Deep Dive

## The Problem with Traditional PR Workflows

### Traditional (Slow)
```
Day 1: Create PR1 → Wait for review
Day 2: Address feedback
Day 3: Merge PR1
Day 4: Create PR2 → Wait for review
Day 5: Address feedback
Day 6: Merge PR2
Day 7: Create PR3 → Wait for review
...
Timeline: 2-3 weeks for a 5-PR feature
```

### Stacked (Fast)
```
Day 1: Create PR1, PR2, PR3, PR4, PR5 (all at once)
Day 1-2: Reviews happen in parallel
Day 2: Merge all (automatically, bottom-up)
Timeline: 2-3 days for a 5-PR feature
```

**Speed improvement: 5-7x faster**

---

## Stacked PRs: Detailed Guide

### Core Concepts

#### What is a Stack?
A sequence of PRs where each builds on the previous:

```
main
  ↓
PR1: Add database schema
  ↓
PR2: Add API endpoints (depends on PR1)
  ↓
PR3: Add UI components (depends on PR2)
  ↓
PR4: Add E2E tests (depends on PR3)
```

#### Benefits
- **Parallel review**: All PRs reviewed simultaneously
- **Smaller PRs**: Easier to review (100 lines vs 400 lines)
- **Better commits**: Each PR tells a clear story
- **Faster feedback**: Don't wait for PR1 to merge before working on PR2
- **Easier to revert**: Can revert just PR3 without losing PR1-2

#### Challenges
- **Merge conflicts**: Changes to PR1 require updating PR2-4
- **Mental overhead**: Tracking dependencies
- **Tool support**: GitHub doesn't natively support stacks well
- **Review coordination**: Need clear communication

---

## Tool Comparison: Stacked PRs

### 1. Graphite (Recommended)

**Best for:** Teams serious about stacked PRs, willing to adopt new workflow

#### Features
- Purpose-built for stacked PRs
- CLI + web dashboard
- Auto-rebase when parent changes
- Visual stack view
- Slack/Linear integrations
- Merge queue (auto-merges bottom-up)

#### Installation
```bash
npm install -g @withgraphite/graphite-cli
gt auth --token YOUR_GITHUB_TOKEN
gt repo init
```

#### Workflow
```bash
# Start from main
gt checkout main
gt pull

# Create first PR in stack
gt branch create "add-user-model"
# Make changes to user model
git add .
git commit -m "Add User model with validation"

# Create second PR (stacked on first)
gt branch create "add-user-api"
# Make changes to API
git add .
git commit -m "Add User API endpoints"

# Create third PR (stacked on second)
gt branch create "add-user-ui"
# Make changes to UI
git add .
git commit -m "Add User management UI"

# Submit entire stack at once
gt stack submit

# View stack
gt log short
# Output:
#   ◉ add-user-ui (PR #123)
#   │
#   ◉ add-user-api (PR #122)
#   │
#   ◉ add-user-model (PR #121)
#   │
#   ◉ main
```

#### Handling Changes
```bash
# Reviewer asks for changes on PR #121
gt checkout add-user-model
# Make changes
git add .
git commit -m "Address review feedback"

# Auto-rebase downstream PRs
gt stack submit --restack

# Graphite automatically updates PR #122 and #123
```

#### Merging
```bash
# Approve PR #121, #122, #123 on GitHub
# Graphite's merge queue automatically merges bottom-up:
# 1. Merge #121
# 2. Rebase and merge #122
# 3. Rebase and merge #123
```

#### Pricing
- Free: Up to 5 users
- Team: $15/user/month
- Enterprise: Custom

#### Pros
- Best UX for stacked workflows
- Visual dashboard
- Auto-restack saves time
- Merge queue prevents conflicts

#### Cons
- Requires CLI adoption
- Team must learn new tool
- Cost for larger teams

---

### 2. Aviator

**Best for:** Teams wanting stacked PRs + advanced merge queue features

#### Features
- Stacked PRs support
- Intelligent merge queue (runs tests in parallel)
- Auto-rebase and auto-merge
- Slack notifications
- JIRA integration
- CI optimization (skips redundant tests)

#### Workflow
Similar to Graphite but with more focus on merge queue optimization.

```bash
# Use git branches normally
git checkout -b feature/step-1
# ... make changes ...
git push

# Create PR on GitHub
# Mark as "depends on" in PR description

# Aviator handles the rest:
# - Tracks dependencies
# - Merges in correct order
# - Runs minimal tests needed
```

#### Merge Queue Intelligence
- **Test parallelization**: Tests PRs in parallel when possible
- **Speculative merges**: Assumes PR will pass, starts testing next PR
- **Automatic retry**: Re-runs flaky tests automatically
- **Conflict resolution**: Auto-rebases when possible

#### Pricing
- Free: Up to 5 users
- Team: $20/user/month
- Enterprise: Custom

#### Pros
- Excellent merge queue
- Reduces CI time significantly
- Good for large teams with long CI runs

#### Cons
- More expensive than Graphite
- Heavier weight (more features = more complexity)

---

### 3. ghstack (Free, Lightweight)

**Best for:** Small teams, budget-conscious, comfortable with CLI

#### Features
- Free and open source
- Lightweight CLI
- Works directly with GitHub
- No external service needed

#### Installation
```bash
pip install ghstack
ghstack auth
```

#### Workflow
```bash
# Create commits locally (don't create branches manually)
git checkout main

# Make first change
# ... edit files ...
git commit -m "Add User model"

# Make second change (depends on first)
# ... edit files ...
git commit -m "Add User API"

# Make third change (depends on second)
# ... edit files ...
git commit -m "Add User UI"

# Submit all as separate PRs
ghstack submit

# ghstack creates:
# - PR #101 (just first commit)
# - PR #102 (first + second commit, marked as depends on #101)
# - PR #103 (all commits, marked as depends on #102)
```

#### Handling Changes
```bash
# Edit earlier commit
git rebase -i HEAD~3
# Edit the commit
git add .
git commit --amend

# Re-submit
ghstack submit

# ghstack updates all affected PRs
```

#### Pros
- Free
- No external service
- Simple model (commit = PR)

#### Cons
- Less polished UX
- Manual merge coordination
- No merge queue
- GitHub UI shows "depends on" in description, not native

---

### 4. git-branchless (Free, Advanced)

**Best for:** Power users comfortable with advanced git

#### Features
- Free and open source
- Advanced undo/redo
- Visualize commit graph
- Rebase automation
- Not GitHub-specific (works with any git host)

#### Installation
```bash
brew install git-branchless  # macOS
# or
cargo install git-branchless  # Rust

git branchless init
```

#### Workflow
```bash
# Work on commits (similar to ghstack)
git commit -m "Step 1"
git commit -m "Step 2"
git commit -m "Step 3"

# View graph
git smartlog

# Create PRs (manual, or use helper script)
git branchless submit

# Edit earlier commit
git rebase -i main
# Interactive rebase UI

# Auto-rebase descendants
git branchless restack
```

#### Pros
- Free
- Very powerful
- Great for complex history manipulation
- Works with GitHub, GitLab, Bitbucket

#### Cons
- Steep learning curve
- Not purpose-built for PRs
- Manual PR creation
- No merge queue

---

### 5. Native GitHub (Basic Stacking)

**Best for:** Teams not ready to adopt new tools

#### Features
- No new tools required
- Uses standard GitHub features
- Manual process

#### Workflow
```bash
# Create first branch
git checkout -b feature/step-1
# ... make changes ...
git push origin feature/step-1
# Create PR #101

# Create second branch (from first)
git checkout -b feature/step-2
# ... make changes ...
git push origin feature/step-2
# Create PR #102, mark base as feature/step-1

# Create third branch (from second)
git checkout -b feature/step-3
# ... make changes ...
git push origin feature/step-3
# Create PR #103, mark base as feature/step-2
```

#### PR Description Template
```markdown
## Stack
- PR #101: Add User model
- PR #102: Add User API ⬅️ This PR
- PR #103: Add User UI (depends on this)

## Depends on
#101

## Required for
#103
```

#### Handling Changes
```bash
# If PR #101 changes, manually rebase:
git checkout feature/step-2
git rebase feature/step-1
git push --force-with-lease

git checkout feature/step-3
git rebase feature/step-2
git push --force-with-lease
```

#### Merging
```bash
# Must merge in order manually:
# 1. Merge PR #101
# 2. Change base of PR #102 to main
# 3. Merge PR #102
# 4. Change base of PR #103 to main
# 5. Merge PR #103
```

#### Pros
- No new tools
- No cost
- Uses standard GitHub

#### Cons
- Very manual
- Error-prone
- Time-consuming
- Poor visualization
- Easy to forget to update base branch

---

## Tool Comparison Matrix

| Feature | Graphite | Aviator | ghstack | git-branchless | Native GH |
|---------|----------|---------|---------|----------------|-----------|
| **Cost** | $15/user/mo | $20/user/mo | Free | Free | Free |
| **Setup difficulty** | Easy | Easy | Medium | Hard | None |
| **CLI required** | Yes | Optional | Yes | Yes | No |
| **Auto-restack** | Yes | Yes | Yes | Yes | No |
| **Visual stack** | Yes (web) | Yes (web) | No | Yes (CLI) | No |
| **Merge queue** | Yes | Yes (best) | No | No | No |
| **GitHub integration** | Native | Native | Good | Manual | Native |
| **Learning curve** | Low | Low | Medium | High | Medium |
| **Team coordination** | Excellent | Excellent | Good | Manual | Manual |
| **CI optimization** | No | Yes | No | No | No |

---

## Trunk-Based Development Strategies

### What is Trunk-Based Development?

**Core principle:** All developers work on a single branch (trunk/main), merging frequently (multiple times per day).

**Contrasts with:**
- **Git Flow**: Long-lived feature branches
- **GitHub Flow**: Feature branches merged when complete

### Why Trunk-Based Development?

#### Benefits
- **Fewer merge conflicts**: Small, frequent merges
- **Faster feedback**: Changes visible to team immediately
- **Simpler workflow**: No branch management overhead
- **Better CI**: Always testing main branch
- **Enables CD**: Can deploy main at any time

#### Requirements
- Feature flags (hide incomplete features)
- Good test coverage (confidence to merge)
- Fast CI (don't break main)
- Team discipline (merge small, merge often)

---

## Trunk-Based Development: Implementation Models

### Model 1: Pure Trunk (Most Aggressive)

**How it works:**
- Developers commit directly to main (or very short-lived branches <24h)
- Feature flags hide incomplete features
- Review happens post-commit (pair programming or async)

```bash
# Morning
git pull origin main

# Work on feature (with feature flag)
# ... edit code ...
git add .
git commit -m "Add checkout flow (behind feature flag)"

# Push to main
git push origin main

# Team reviews async
# Feedback addressed in subsequent commits
```

#### When to use
- Very high-trust teams
- Excellent test coverage
- Experienced engineers
- Fast feedback culture

#### Example: Facebook
- Commits directly to main
- Heavy use of feature flags
- Extensive automated testing
- Post-commit review common

---

### Model 2: Short-Lived Branches (Balanced)

**How it works:**
- Create branch in morning
- Work for a few hours
- Create PR
- Merge same day (or within 24h)
- Use feature flags for multi-day work

```bash
# Morning
git checkout -b feature/quick-fix

# Work for 2-4 hours
# ... make changes ...

# Create PR
git push origin feature/quick-fix
gh pr create --title "Fix checkout bug"

# Review + merge within hours
# Delete branch
```

#### Branch Lifetime Rules
- **Max 24 hours**: Delete or merge by end of day
- **Max 400 lines**: Split larger changes
- **Daily sync**: Pull from main frequently
- **Feature flags**: For multi-day work

#### When to use
- Most teams (good balance)
- Transitioning from longer branches
- Need some review before merge

#### Example: Google
- Short-lived branches (often <4 hours)
- Fast review process (median 4 hours)
- Extensive automated testing
- Owners files for required reviewers

---

### Model 3: Stacked Branches (Structured)

**How it works:**
- Create small, dependent branches
- Each represents a logical unit
- All merged within 1-3 days
- Feature flags for incomplete features

```bash
# Day 1 morning: Create stack
gt branch create "add-schema"
# Work 1-2 hours
gt branch create "add-api"
# Work 1-2 hours
gt branch create "add-ui"
# Work 1-2 hours

# Submit all for review
gt stack submit

# Day 1 afternoon: Address feedback in parallel
# Day 2: Merge entire stack
```

#### When to use
- Medium-sized features (need structure)
- Teams using Graphite/Aviator
- Want fast delivery but clear milestones

#### Example: Stripe
- Heavy use of stacked PRs
- Small, well-defined changes
- Fast review cycle
- Feature flags for incomplete features

---

### Model 4: Trunk + Experimental Branches (Hybrid)

**How it works:**
- Day-to-day work: Short-lived branches to main
- Experiments/spikes: Separate long-lived branch
- Periodically sync main → experimental
- When ready: Rebase and merge or reimplement

```
main (protected, daily merges)
  │
  ├── feature/quick-fix (2 hours)
  ├── feature/bug-123 (4 hours)
  └── feature/new-feature (8 hours)

experimental/new-arch (weeks)
  ├── Daily sync from main
  └── Eventually: Rebase + merge to main
```

#### When to use
- Need to explore radical changes
- Uncertain about approach
- Want to maintain trunk velocity
- Can't use feature flags effectively

#### Example: Experimental Rewrite
```bash
# Create experimental branch
git checkout -b experimental/new-auth-system

# Work freely for weeks
# ... lots of commits ...

# Daily: Pull from main
git pull origin main --rebase

# When ready: Rebase and merge
git rebase -i main  # Clean up commits
git checkout main
git merge experimental/new-auth-system

# Or: Reimplement cleanly
# Review experimental code
# Build production version in small PRs
```

---

## Feature Flags: The Key to Trunk-Based Development

### Why Feature Flags?

**Problem:** How do you merge incomplete features without breaking production?

**Solution:** Hide incomplete code behind flags.

```typescript
// Incomplete feature merged to main
function checkout() {
  if (featureFlags.isEnabled('new-checkout-flow')) {
    return newCheckoutFlow()  // WIP, only for internal testing
  }
  return oldCheckoutFlow()  // Production
}
```

### Feature Flag Patterns

#### Pattern 1: Simple Boolean
```typescript
const NEW_FEATURE_ENABLED = false  // or env var

if (NEW_FEATURE_ENABLED) {
  // New code
} else {
  // Old code
}
```

**Pros:** Simple
**Cons:** All-or-nothing, can't test with subset of users

---

#### Pattern 2: Percentage Rollout
```typescript
function isEnabled(userId: string, percentage: number): boolean {
  const hash = hashString(userId)
  return (hash % 100) < percentage
}

// 10% of users see new feature
if (isEnabled(user.id, 10)) {
  return newFeature()
}
return oldFeature()
```

**Pros:** Gradual rollout, can measure impact
**Cons:** Requires user context

---

#### Pattern 3: User Allowlist
```typescript
const BETA_TESTERS = ['user-1', 'user-2', 'team@company.com']

if (BETA_TESTERS.includes(user.id) || BETA_TESTERS.includes(user.email)) {
  return newFeature()
}
return oldFeature()
```

**Pros:** Controlled testing, easy to debug
**Cons:** Manual management

---

#### Pattern 4: Multi-Variant (A/B Testing)
```typescript
const variant = getFeatureVariant('checkout-flow', user.id)

switch (variant) {
  case 'control':
    return oldCheckout()
  case 'variant-a':
    return checkoutWithUpsell()
  case 'variant-b':
    return checkoutWithCoupon()
}
```

**Pros:** Can test multiple approaches
**Cons:** More complex

---

### Feature Flag Lifecycle

```
Development → Internal Testing → Beta → 10% → 50% → 100% → Remove Flag
```

#### Stage 1: Development (0%)
```typescript
if (featureFlags.isEnabled('new-feature', { default: false })) {
  // New code (disabled in production)
}
```

#### Stage 2: Internal Testing (allowlist)
```typescript
if (featureFlags.isEnabled('new-feature', user, {
  allowlist: ['internal-team@company.com']
})) {
  // Team can test
}
```

#### Stage 3: Beta (5-10%)
```typescript
if (featureFlags.isEnabled('new-feature', user, {
  percentage: 10
})) {
  // 10% of users
}
```

#### Stage 4: Gradual Rollout (50% → 100%)
```typescript
// Increase percentage daily if metrics look good
if (featureFlags.isEnabled('new-feature', user, {
  percentage: 50  // Day 1
  percentage: 75  // Day 2
  percentage: 100 // Day 3
})) {
  return newFeature()
}
```

#### Stage 5: Remove Flag
```typescript
// Once at 100% for a week, remove flag entirely
// Before:
if (featureFlags.isEnabled('new-feature')) {
  return newFeature()
} else {
  return oldFeature()
}

// After:
return newFeature()
// Delete oldFeature()
```

---

### Feature Flag Best Practices

#### 1. Default to Safe State
```typescript
// Good: Defaults to old behavior if flag service fails
const enabled = featureFlags.isEnabled('new-feature') ?? false

// Bad: Defaults to new behavior if flag service fails
const enabled = featureFlags.isEnabled('new-feature') ?? true
```

#### 2. Flag at Component Boundary
```typescript
// Good: Clean separation
function App() {
  if (useFeatureFlag('new-dashboard')) {
    return <NewDashboard />
  }
  return <OldDashboard />
}

// Bad: Flag scattered throughout
function Dashboard() {
  return (
    <div>
      {useFeatureFlag('new-header') ? <NewHeader /> : <OldHeader />}
      {/* ... lots of code ... */}
      {useFeatureFlag('new-footer') ? <NewFooter /> : <OldFooter />}
    </div>
  )
}
```

#### 3. Remove Flags Quickly
- Set removal deadline when creating flag
- Track flag age
- Alert on flags older than 30 days
- Treat old flags as tech debt

#### 4. Document Flags
```typescript
// flags.ts
export const FEATURE_FLAGS = {
  'new-checkout': {
    description: 'Redesigned checkout flow with upsells',
    created: '2024-01-15',
    owner: 'checkout-team',
    jira: 'CHECKOUT-123',
    removeBy: '2024-03-01'
  }
}
```

---

## Combining Stacked PRs + Trunk-Based Development

### The Power Combo

**Stacked PRs** + **Trunk-Based Development** + **Feature Flags** = Maximum velocity

```
Day 1: Create stack of 5 PRs (each 50-100 lines)
  ├── PR1: Add feature flag
  ├── PR2: Add backend logic (behind flag)
  ├── PR3: Add API endpoint (behind flag)
  ├── PR4: Add UI component (behind flag)
  └── PR5: Add tests

Day 1-2: Review all PRs in parallel

Day 2: Merge entire stack to main (feature still disabled)

Day 3: Enable for internal team

Day 4-7: Gradual rollout (10% → 50% → 100%)

Day 8: Remove feature flag
```

### Example Workflow

#### Week 1: Build Feature
```bash
# Monday: Create stack
gt branch create "add-new-dashboard-flag"
# Add feature flag, merge to main

gt branch create "add-dashboard-backend"
# Add backend logic (behind flag), merge to main

gt branch create "add-dashboard-api"
# Add API (behind flag), merge to main

gt branch create "add-dashboard-ui"
# Add UI (behind flag), merge to main

gt branch create "add-dashboard-tests"
# Add E2E tests, merge to main

# By Friday: All code in main, feature disabled
```

#### Week 2: Rollout
```bash
# Monday: Enable for team
featureFlags.set('new-dashboard', { allowlist: ['team@company'] })

# Tuesday: Monitor, fix bugs in small PRs

# Wednesday: Enable for 10%
featureFlags.set('new-dashboard', { percentage: 10 })

# Thursday: Increase to 50% (if metrics good)
featureFlags.set('new-dashboard', { percentage: 50 })

# Friday: 100% rollout
featureFlags.set('new-dashboard', { percentage: 100 })
```

#### Week 3: Cleanup
```bash
# Monday: Remove flag (if stable for 1 week)
git checkout -b cleanup/remove-dashboard-flag

# Remove flag checks
# Delete old code
# Simplify logic

# Merge to main
```

---

## Migration Guide: From Long-Lived Branches to Trunk-Based

### Current State: Long-Lived Branches
```
main
  ├── feature/big-refactor (3 weeks old, 2000 lines)
  ├── feature/new-api (2 weeks old, 1500 lines)
  └── bugfix/auth-issue (1 week old, 300 lines)
```

**Problems:**
- Merge conflicts
- Stale branches
- Large, hard-to-review PRs
- Slow feedback

---

### Phase 1: Reduce Branch Lifetime (Week 1-2)

**Goal:** No branch older than 1 week

#### Actions
1. **Merge or delete all branches >2 weeks old**
   - Merge if ready (even if imperfect)
   - Use feature flags to hide incomplete work
   - Delete if no longer relevant

2. **Set branch lifetime policy**
   - Max 1 week per branch
   - Daily reminder for old branches
   - Auto-close branches after 10 days

3. **Break large PRs into smaller ones**
   - 2000-line PR → 5x 400-line PRs
   - Use stacked PRs

```bash
# Before: One huge PR
git checkout -b feature/big-refactor
# ... 3 weeks of work ...
# 2000 lines changed

# After: Stack of smaller PRs
gt branch create "refactor-step-1-models"
# ... 400 lines ...
gt branch create "refactor-step-2-api"
# ... 400 lines ...
gt branch create "refactor-step-3-ui"
# ... 400 lines ...
# Merge each within days
```

---

### Phase 2: Introduce Feature Flags (Week 3-4)

**Goal:** Can merge incomplete work safely

#### Actions
1. **Set up feature flag system**
   - Start simple (env vars or config file)
   - Later: Adopt LaunchDarkly/Unleash

2. **Wrap all new features in flags**
   ```typescript
   if (featureFlags.isEnabled('new-feature')) {
     return newImplementation()
   }
   return existingImplementation()
   ```

3. **Merge to main daily**
   - Even if feature incomplete
   - Flag keeps it hidden
   - Team sees progress

---

### Phase 3: Adopt Stacked PRs (Week 5-6)

**Goal:** Review PRs in parallel

#### Actions
1. **Choose tool** (Graphite recommended)
2. **Train team on stacked workflow**
3. **Start with one team/project**
4. **Expand gradually**

---

### Phase 4: Daily Merges (Week 7-8)

**Goal:** Every developer merges to main daily

#### Actions
1. **Set expectation:** Merge at least once per day
2. **Track metrics:** Measure merge frequency
3. **Celebrate:** Recognize teams with high merge frequency
4. **Retrospect:** Identify blockers

---

### Phase 5: Continuous Deployment (Week 9+)

**Goal:** Deploy main to production automatically

#### Actions
1. **Auto-deploy to staging** (every merge)
2. **Monitor staging closely**
3. **Gradually introduce auto-deploy to production**
   - Start with low-traffic times
   - Use feature flags for rollback
   - Build confidence over weeks

---

## Success Metrics

### Track These Metrics

#### Velocity Metrics
- **Merge frequency**: Merges per developer per day (target: >2)
- **PR cycle time**: Time from PR creation to merge (target: <24h)
- **PR size**: Lines changed per PR (target: <400 lines for 80% of PRs)
- **Branch lifetime**: Time from branch creation to merge (target: <3 days)

#### Quality Metrics
- **Build success rate**: % of main builds that pass (target: >95%)
- **Revert rate**: % of merges that get reverted (target: <2%)
- **Bug escape rate**: Production bugs per merge (track trend)
- **Feature flag cleanup**: % of flags removed within 30 days (target: >80%)

#### Process Metrics
- **Review SLA compliance**: % of PRs reviewed within SLA (target: >90%)
- **Auto-merge rate**: % of PRs auto-merged (docs, tests) (target: >20%)
- **Stacked PR adoption**: % of feature work using stacks (track trend)

---

## Troubleshooting Common Issues

### Issue 1: "Stacked PRs are too complex"

**Solution:**
- Start with 2-PR stacks (not 5-PR stacks)
- Use Graphite (handles complexity for you)
- Practice on small features first
- Pair with experienced teammate

### Issue 2: "We keep breaking main"

**Solution:**
- Improve test coverage
- Add pre-merge checks (lint, type check, tests)
- Use feature flags more aggressively
- Review branch protection rules
- Consider required approvals

### Issue 3: "Reviews are still slow"

**Solution:**
- Implement Ship/Show/Ask
- Enable auto-merge for safe changes
- Set stricter SLAs
- Rotate review responsibility
- Consider pairing instead of async review

### Issue 4: "Feature flags create tech debt"

**Solution:**
- Set removal deadline when creating flag
- Track flag age (alert on old flags)
- Include flag removal in definition of done
- Regular cleanup sprints
- Automate flag removal (generate cleanup PRs)

### Issue 5: "Merge conflicts with stacked PRs"

**Solution:**
- Use tools that auto-restack (Graphite, Aviator)
- Merge frequently (don't let stack sit)
- Keep PRs small (easier to rebase)
- Coordinate with team (Slack updates)

---

## Summary: Recommended Setup

### For Small Teams (<10 engineers)

**Tools:**
- GitHub native + ghstack (free)
- Simple feature flags (env vars)
- Mergify for auto-merge

**Process:**
- Short-lived branches (<3 days)
- Stacked PRs for medium features
- Ship/Show/Ask model
- Daily review time

**Investment:** Minimal (mostly process)

---

### For Medium Teams (10-50 engineers)

**Tools:**
- Graphite ($15/user/month)
- LaunchDarkly or Unleash (feature flags)
- Mergify for auto-merge
- Slack integration

**Process:**
- Trunk-based development (branches <24h)
- Stacked PRs for all multi-part work
- Tiered review system
- Automated metrics dashboard

**Investment:** $200-750/month + setup time

---

### For Large Teams (50+ engineers)

**Tools:**
- Graphite or Aviator ($15-20/user/month)
- LaunchDarkly (enterprise)
- Custom automation
- LinearB or similar (metrics)

**Process:**
- Pure trunk-based development
- Stacked PRs as default
- Extensive automation
- Dedicated developer productivity team

**Investment:** $1000+/month + dedicated team

---

## Conclusion

**Stacked PRs** and **trunk-based development** are complementary practices that enable high-velocity teams to:
- Ship faster (5-7x faster delivery)
- Maintain quality (smaller, focused changes)
- Reduce conflicts (frequent integration)
- Improve collaboration (everyone sees work early)

Start with **short-lived branches**, add **feature flags**, adopt **stacked PRs**, and gradually move toward **trunk-based development** with **continuous deployment**.

The tools exist, the practices are proven. The only question is: How fast do you want to move?
