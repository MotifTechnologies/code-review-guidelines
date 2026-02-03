# Code Review Guidelines for AI/ML Teams
## Optimized for Long-Running Training Experiments & AI-Assisted Development

**Version:** 1.0
**Last Updated:** February 2026
**Audience:** AI/ML Engineering Teams

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [The Problem We're Solving](#the-problem-were-solving)
3. [Tiered Review System](#tiered-review-system)
4. [Review Process by Code Category](#review-process-by-code-category)
5. [Handling Experimental Branches](#handling-experimental-branches)
6. [AI-Assisted Code Review](#ai-assisted-code-review)
7. [Vibe Coding Guidelines](#vibe-coding-guidelines)
8. [Review SLAs and Metrics](#review-slas-and-metrics)
9. [Tools and Automation](#tools-and-automation)
10. [Implementation Roadmap](#implementation-roadmap)

---

## Executive Summary

This document establishes code review guidelines specifically designed for AI companies with:
- Long-running training experiments (days/weeks)
- High experimentation velocity requirements
- AI-assisted development ("vibe coding") practices
- The need to balance speed with code quality

**Key Principles:**
1. **Not all code needs the same level of review** - Tiered review system
2. **Experimentation should not be blocked** - Ship/Show/Ask model
3. **AI-generated code requires different review focus** - C.L.E.A.R. framework
4. **Automate the automatable** - Reserve human attention for high-value review

---

## The Problem We're Solving

### Current State
- Review process is a bottleneck (~41% of code is now AI-assisted)
- Team members run experiments on non-reviewed branches
- PRs are created after experiments complete, making review difficult
- Long-running training means code diverges significantly before review

### The New Reality (2025-2026)
- AI coding tools have reached mass adoption (84% developer adoption)
- Code generation is faster than ever; review capacity hasn't scaled
- Monthly GitHub pushes exceed 82M, merged PRs hit 43M
- **Review throughput, not implementation speed, determines delivery velocity**

### Solution Framework
```
┌─────────────────────────────────────────────────────────────┐
│                    TIERED REVIEW SYSTEM                      │
├─────────────────────────────────────────────────────────────┤
│  SHIP (Auto-merge)  │  SHOW (Async)  │  ASK (Full Review)  │
│  Config, docs,      │  Standard      │  Architecture,      │
│  experiments        │  features      │  security, core     │
└─────────────────────────────────────────────────────────────┘
```

---

## Tiered Review System

### Overview

Not all changes carry equal risk. Apply review effort proportionally.

| Tier | Review Type | SLA | When to Use |
|------|-------------|-----|-------------|
| **SHIP** | Auto-merge | Immediate | Config changes, documentation, experiment configs |
| **SHOW** | Async notification | 24h acknowledgment | Standard features, non-critical bug fixes |
| **ASK** | Full synchronous review | 4h response, 24h completion | Architecture changes, security, production pipelines |

### Tier 1: SHIP (Auto-Merge)

**Criteria for auto-merge:**
- [ ] All automated tests pass
- [ ] Linting and type checks pass
- [ ] Security scans clean
- [ ] Change is in allowed category (see below)

**Allowed Categories:**
```
✓ Documentation updates (README, comments, docs/)
✓ Experiment configuration files (configs/, experiments/)
✓ Development environment configs (.vscode/, .devcontainer/)
✓ Dependency version bumps (with lockfile)
✓ Generated code (if generation is verified)
✓ Experiment notebook outputs (.ipynb outputs)
```

**Implementation:**
```yaml
# .github/auto-merge.yml
auto_merge:
  paths:
    - "docs/**"
    - "experiments/configs/**"
    - "*.md"
    - ".vscode/**"
  conditions:
    - ci_passed
    - security_scan_clean
    - no_production_code_changes
```

### Tier 2: SHOW (Async Notification)

**Process:**
1. Developer merges after CI passes
2. Team is notified asynchronously
3. Reviewers have 24h to raise concerns
4. If concerns raised, address in follow-up PR

**Criteria:**
- Standard feature development
- Bug fixes (non-security)
- Refactoring within existing patterns
- Test additions/modifications

**Notification Template:**
```markdown
## [SHOW] Feature: {title}

**What:** Brief description
**Why:** Business/technical justification
**Risk:** Low/Medium
**Rollback:** How to revert if issues found

Changes: {link to diff}
```

### Tier 3: ASK (Full Review Required)

**Must be used for:**
- [ ] Production ML pipeline changes
- [ ] Training infrastructure modifications
- [ ] Security-sensitive code
- [ ] API contracts and interfaces
- [ ] Database schema changes
- [ ] Authentication/authorization
- [ ] Cost-impacting changes (compute, storage)
- [ ] New external dependencies

**Review Requirements:**
- Minimum 1 senior engineer approval
- Security review for sensitive changes
- Architecture review for structural changes
- All comments resolved before merge

---

## Review Process by Code Category

### ML/Training Code Categories

| Category | Review Tier | Special Considerations |
|----------|-------------|------------------------|
| **Experiment Scripts** | SHIP/SHOW | Reproducibility check, resource usage |
| **Training Configs** | SHIP | Validate against schema |
| **Model Architecture** | ASK | Performance implications, memory usage |
| **Data Pipeline** | ASK | Data integrity, privacy compliance |
| **Evaluation Metrics** | SHOW | Correctness verification |
| **Inference Code** | ASK | Latency, error handling |
| **Production Pipeline** | ASK | Full review + staging test |

### Experiment Code Review Checklist

```markdown
## Experiment Review Checklist

### Reproducibility
- [ ] Random seeds are set and documented
- [ ] Environment/dependencies are pinned
- [ ] Data version is tracked
- [ ] Hyperparameters are logged

### Resource Management
- [ ] GPU memory usage is reasonable
- [ ] Checkpointing is implemented for long runs
- [ ] Resource cleanup on failure

### Logging & Tracking
- [ ] Metrics are logged to experiment tracker
- [ ] Model artifacts are versioned
- [ ] Training curves are captured

### Code Quality (Lighter Standard)
- [ ] Code runs without errors
- [ ] Key logic is understandable
- [ ] No hardcoded credentials
```

### Production Code Review Checklist

```markdown
## Production Review Checklist

### Functionality
- [ ] Meets requirements
- [ ] Edge cases handled
- [ ] Error handling is comprehensive

### Performance
- [ ] No obvious performance issues
- [ ] Memory usage is acceptable
- [ ] Scales appropriately

### Security
- [ ] Input validation present
- [ ] No credential exposure
- [ ] OWASP top 10 considered

### Maintainability
- [ ] Code is readable
- [ ] Tests are adequate
- [ ] Documentation updated

### ML-Specific
- [ ] Model versioning in place
- [ ] Fallback behavior defined
- [ ] Monitoring hooks present
```

---

## Handling Experimental Branches

### The Challenge

Training experiments often take days or weeks. Blocking experimentation on review creates:
- Developers working on unreviewed branches for extended periods
- Large, difficult-to-review PRs after experiment completion
- Code divergence and merge conflicts

### Solution: Experiment Branch Protocol

```
┌──────────────────────────────────────────────────────────────┐
│                 EXPERIMENT BRANCH WORKFLOW                    │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  1. CREATE: exp/{username}/{experiment-name}                 │
│     └── Register in experiment tracker                       │
│                                                              │
│  2. DEVELOP: Work freely, commit often                       │
│     └── Auto-sync with main daily (merge main → exp)        │
│                                                              │
│  3. CHECKPOINT: Weekly mini-reviews (optional)               │
│     └── Lightweight async review of key changes              │
│                                                              │
│  4. COMPLETE: When experiment concludes                      │
│     └── Create PR with experiment results                    │
│     └── Review focuses on: what to keep vs discard           │
│                                                              │
│  5. PRODUCTIONIZE: If successful                             │
│     └── Full ASK review for production-bound code            │
│     └── Refactor experiment code to production standards     │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

### Experiment Branch Rules

```yaml
# Branch protection for experiment branches
experiment_branches:
  pattern: "exp/**"
  rules:
    - allow_force_push: true
    - require_ci: false  # Allow broken experiments
    - auto_delete_after: 90_days
    - require_experiment_registration: true
```

### Experiment Registration Template

```yaml
# experiments/registry/{experiment-id}.yaml
experiment:
  id: exp-2026-001
  name: "Improved attention mechanism"
  owner: "@username"
  branch: "exp/username/attention-v2"
  hypothesis: "New attention reduces training time by 20%"
  start_date: 2026-02-01
  expected_duration: "2 weeks"
  resources:
    gpus: 8
    estimated_cost: "$5000"
  success_criteria:
    - "Training time < 80% of baseline"
    - "Accuracy >= baseline"
  status: in_progress
```

### Post-Experiment PR Template

```markdown
## Experiment Results: {experiment-name}

### Hypothesis
{What we were testing}

### Results
- **Outcome:** Success / Partial / Failed
- **Key Metrics:** {metrics vs baseline}
- **Artifacts:** {links to models, logs}

### Code to Keep
- {file1}: {reason}
- {file2}: {reason}

### Code to Discard
- {file3}: {reason - experimental only}

### Production Path
- [ ] Refactor needed: {yes/no}
- [ ] Estimated effort: {t-shirt size}
- [ ] Dependencies: {any blockers}

### Learnings
{What we learned, even if experiment failed}
```

---

## AI-Assisted Code Review

### The New Bottleneck

> "The big bottleneck in shipping software is the code review process, especially as you grow your team." — Harjot Gill, CodeRabbit founder

AI tools have shifted the bottleneck:
- **Before:** Writing code was slow, review was manageable
- **Now:** Writing code is fast, review capacity is the constraint

### AI-Assisted Review Strategy

```
┌─────────────────────────────────────────────────────────────┐
│              AI + HUMAN REVIEW WORKFLOW                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  PR Created                                                 │
│      │                                                      │
│      ▼                                                      │
│  ┌─────────────────┐                                        │
│  │   AI Review     │  ← Automated (immediate)               │
│  │   - Style       │                                        │
│  │   - Bugs        │                                        │
│  │   - Security    │                                        │
│  │   - Tests       │                                        │
│  └────────┬────────┘                                        │
│           │                                                 │
│           ▼                                                 │
│  ┌─────────────────┐                                        │
│  │  Human Review   │  ← Focused on high-value areas         │
│  │  - Architecture │                                        │
│  │  - Design       │                                        │
│  │  - Business     │                                        │
│  │  - Intent       │                                        │
│  └────────┬────────┘                                        │
│           │                                                 │
│           ▼                                                 │
│       Merge                                                 │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### What AI Reviews Well (Automate These)

| Category | AI Capability | Tools |
|----------|--------------|-------|
| **Style/Formatting** | Excellent | Prettier, ESLint, Black |
| **Type Errors** | Excellent | TypeScript, mypy, Pyright |
| **Common Bugs** | Good | CodeRabbit, Qodo, SonarQube |
| **Security Patterns** | Good | Snyk, Semgrep, GitGuardian |
| **Test Coverage** | Good | Codecov, Coverage.py |
| **Documentation** | Moderate | AI doc generators |

### What Humans Must Review (Focus Here)

| Category | Why AI Struggles |
|----------|------------------|
| **Architectural Fit** | Requires system-wide context |
| **Business Logic** | Needs domain knowledge |
| **Performance Trade-offs** | Context-dependent decisions |
| **User Experience** | Subjective, requires empathy |
| **Security (Advanced)** | Novel attack vectors |
| **Code Intent** | "Does this solve the right problem?" |

### AI Review Tool Recommendations

| Tool | Best For | Integration |
|------|----------|-------------|
| **CodeRabbit** | Comprehensive AI review | GitHub, GitLab |
| **Qodo (formerly CodiumAI)** | Test generation, review | VS Code, GitHub |
| **GitHub Copilot** | In-editor suggestions | GitHub native |
| **Graphite** | Stacked PRs, review flow | GitHub |
| **Aikido** | Security-focused review | CI/CD |

---

## Vibe Coding Guidelines

### What is Vibe Coding?

> "Vibe coding" refers to a coding approach using LLMs where programmers generate working code via natural language descriptions rather than writing it manually. A key part is accepting AI-generated code without fully understanding it. — Andrej Karpathy, 2025

### The Review Challenge

When developers don't write code line-by-line:
- **Comprehension gap:** Reviewer didn't participate in prompt engineering
- **Pattern unfamiliarity:** AI generates different patterns than humans
- **Bulk generation:** Larger volumes create review fatigue
- **False confidence:** Well-formatted code creates false sense of security

### C.L.E.A.R. Framework for Reviewing AI-Generated Code

```
C - Context
    ├── Review the original prompt used
    ├── Understand the requirements
    └── Check generation history/iterations

L - Logic
    ├── Verify the logic is correct
    ├── Check edge cases
    └── Validate error handling

E - Environment
    ├── Does it fit existing architecture?
    ├── Consistent with codebase patterns?
    └── Dependencies appropriate?

A - Assurance
    ├── Test coverage adequate?
    ├── Security implications?
    └── Performance acceptable?

R - Readability
    ├── Can team maintain this?
    ├── Documentation sufficient?
    └── Future developers can understand?
```

### Vibe Coding Review Checklist

```markdown
## Vibe Coding Review Checklist

### Context (Before Looking at Code)
- [ ] What prompt generated this code?
- [ ] What were the requirements?
- [ ] Were there multiple iterations?

### Critical Security Review
- [ ] Input validation present (AI often forgets)
- [ ] Authorization checks in place
- [ ] No SQL injection vulnerabilities
- [ ] No hardcoded secrets
- [ ] Proper error messages (no info leakage)

### AI-Specific Red Flags
- [ ] Overly complex solutions for simple problems
- [ ] Unnecessary abstractions
- [ ] Copy-paste patterns (subtle bugs)
- [ ] Placeholder code left in
- [ ] TODO comments not addressed
- [ ] Hallucinated APIs or libraries

### Integration Verification
- [ ] Works with existing code
- [ ] Follows team conventions
- [ ] Tests actually test the right things
- [ ] Documentation matches behavior
```

### Disclosure Policy

**Recommendation:** Require AI assistance disclosure in PRs

```markdown
## AI Assistance Disclosure

- [ ] No AI assistance used
- [ ] AI assisted (Copilot/Claude/Cursor)
  - Tools used: ___________
  - Extent: Light suggestions / Significant generation / Majority AI-generated
  - All generated code reviewed and understood: Yes / No
```

### Managing AI-Generated Code Debt

**Definition:** Technical debt specifically arising from accepting AI-generated code without full understanding.

**Symptoms:**
- Code that "works" but no one understands why
- Inconsistent patterns across codebase
- Over-engineered solutions
- Missing edge case handling
- Subtle bugs that surface later

**Prevention:**
1. **Test after every generation cycle** - Don't trust "looks correct"
2. **Require understanding** - If you can't explain it, refactor it
3. **Regular refactoring sprints** - Consolidate AI-generated patterns
4. **Documentation requirements** - AI should document, human should verify

---

## Review SLAs and Metrics

### Review SLAs by Tier

| Tier | First Response | Completion | Escalation |
|------|----------------|------------|------------|
| **SHIP** | Automated | Immediate | N/A |
| **SHOW** | 24 hours | 48 hours | After 48h → Slack ping |
| **ASK** | 4 hours | 24 hours | After 24h → Manager notified |

### Key Metrics to Track

```yaml
review_metrics:
  speed:
    - time_to_first_review: "Hours from PR open to first comment"
    - time_to_merge: "Hours from PR open to merge"
    - review_cycles: "Number of review rounds"

  quality:
    - post_merge_issues: "Bugs found after merge"
    - revert_rate: "PRs reverted within 7 days"
    - review_coverage: "% of lines with review comments"

  load:
    - reviews_per_engineer_per_week: "Review workload distribution"
    - pr_size_distribution: "Lines changed histogram"
    - pending_review_age: "Hours PRs wait for review"
```

### Healthy Benchmarks

| Metric | Target | Warning | Critical |
|--------|--------|---------|----------|
| Time to first review | < 4h | 4-8h | > 8h |
| Time to merge (SHOW) | < 24h | 24-48h | > 48h |
| Time to merge (ASK) | < 48h | 48-72h | > 72h |
| Review cycles | < 3 | 3-5 | > 5 |
| Post-merge issues | < 5% | 5-10% | > 10% |
| PR size (lines) | < 400 | 400-800 | > 800 |

### Review Load Balancing

```python
# Pseudo-code for review assignment
def assign_reviewer(pr):
    candidates = get_available_reviewers(pr.affected_areas)

    # Factor in current load
    for reviewer in candidates:
        reviewer.score = (
            reviewer.expertise_match * 0.4 +
            (1 / reviewer.pending_reviews) * 0.3 +
            reviewer.recent_response_time * 0.2 +
            reviewer.timezone_overlap * 0.1
        )

    return candidates.sort_by_score().first()
```

---

## Tools and Automation

### Recommended Tool Stack

```
┌─────────────────────────────────────────────────────────────┐
│                    CODE REVIEW TOOL STACK                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Layer 1: Automated Checks (CI/CD)                          │
│  ├── Linting: ESLint, Pylint, Ruff                         │
│  ├── Typing: TypeScript, mypy, Pyright                     │
│  ├── Testing: pytest, Jest (with coverage)                 │
│  ├── Security: Snyk, Semgrep, GitGuardian                  │
│  └── Style: Prettier, Black, isort                         │
│                                                             │
│  Layer 2: AI-Assisted Review                                │
│  ├── CodeRabbit: Comprehensive AI review                   │
│  ├── Qodo: Test generation + review                        │
│  └── SonarQube: Code quality analysis                      │
│                                                             │
│  Layer 3: Workflow Optimization                             │
│  ├── Graphite: Stacked PRs, review queue                   │
│  ├── LinearB: Engineering metrics                          │
│  └── Sleuth: DORA metrics, deployment tracking             │
│                                                             │
│  Layer 4: Human Review                                      │
│  ├── GitHub/GitLab: Native review interface                │
│  ├── Review Board: Complex review workflows                │
│  └── Slack/Teams: Review notifications                     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### CI/CD Pipeline Configuration

```yaml
# .github/workflows/review-automation.yml
name: Automated Review Checks

on: [pull_request]

jobs:
  tier-classification:
    runs-on: ubuntu-latest
    outputs:
      tier: ${{ steps.classify.outputs.tier }}
    steps:
      - uses: actions/checkout@v4
      - id: classify
        run: |
          # Classify PR tier based on files changed
          if [[ $(git diff --name-only origin/main | grep -E '^(src/|lib/)') ]]; then
            echo "tier=ASK" >> $GITHUB_OUTPUT
          elif [[ $(git diff --name-only origin/main | grep -E '^(docs/|experiments/)') ]]; then
            echo "tier=SHIP" >> $GITHUB_OUTPUT
          else
            echo "tier=SHOW" >> $GITHUB_OUTPUT
          fi

  automated-checks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Lint
        run: npm run lint

      - name: Type Check
        run: npm run typecheck

      - name: Unit Tests
        run: npm test -- --coverage

      - name: Security Scan
        uses: snyk/actions/node@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}

  ai-review:
    runs-on: ubuntu-latest
    steps:
      - name: CodeRabbit Review
        uses: coderabbit-ai/coderabbit-action@v1
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}

  auto-merge:
    needs: [tier-classification, automated-checks]
    if: needs.tier-classification.outputs.tier == 'SHIP'
    runs-on: ubuntu-latest
    steps:
      - name: Auto-merge SHIP tier
        uses: pascalgn/automerge-action@v0.15.6
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          MERGE_METHOD: squash
```

### Stacked PR Workflow (Graphite)

```bash
# Install Graphite CLI
npm install -g @withgraphite/graphite-cli

# Create a stack of dependent PRs
gt branch create feature/step-1
# ... make changes ...
gt commit -m "Step 1: Add data loading"
gt submit  # Creates PR for step 1

gt branch create feature/step-2
# ... make changes ...
gt commit -m "Step 2: Add preprocessing"
gt submit  # Creates PR for step 2, stacked on step 1

# When step 1 is merged, step 2 automatically rebases
```

---

## Implementation Roadmap

### Phase 1: Foundation (Weeks 1-2)

```markdown
## Week 1
- [ ] Establish tier classification criteria
- [ ] Configure branch protection rules
- [ ] Set up experiment branch naming convention
- [ ] Create PR templates for each tier

## Week 2
- [ ] Implement automated CI checks
- [ ] Configure auto-merge for SHIP tier
- [ ] Set up review SLA tracking
- [ ] Create review assignment automation
```

### Phase 2: AI Integration (Weeks 3-4)

```markdown
## Week 3
- [ ] Integrate AI review tool (CodeRabbit/Qodo)
- [ ] Configure AI review scope and rules
- [ ] Train team on AI review output interpretation
- [ ] Establish AI disclosure policy

## Week 4
- [ ] Implement C.L.E.A.R. framework checklists
- [ ] Create vibe coding review guidelines
- [ ] Set up AI-generated code debt tracking
- [ ] Configure security-focused AI scanning
```

### Phase 3: Optimization (Weeks 5-6)

```markdown
## Week 5
- [ ] Implement experiment branch protocol
- [ ] Set up experiment registration system
- [ ] Create post-experiment PR template
- [ ] Configure stacked PR workflow

## Week 6
- [ ] Deploy metrics dashboard
- [ ] Establish review load balancing
- [ ] Create escalation procedures
- [ ] Document and communicate changes
```

### Phase 4: Iteration (Ongoing)

```markdown
## Monthly Review
- [ ] Analyze review metrics
- [ ] Gather team feedback
- [ ] Adjust tier thresholds
- [ ] Update automation rules
- [ ] Refine AI review configuration
```

---

## Appendix A: Quick Reference Card

```
┌─────────────────────────────────────────────────────────────┐
│                    QUICK REFERENCE                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  WHICH TIER?                                                │
│  ───────────                                                │
│  SHIP: Docs, configs, experiments → Auto-merge              │
│  SHOW: Standard features → Async review, 24h                │
│  ASK:  Production, security, arch → Full review, 4h         │
│                                                             │
│  PR SIZE LIMITS                                             │
│  ──────────────                                             │
│  Ideal: < 400 lines                                         │
│  Maximum: 800 lines (split if larger)                       │
│  Review pace: 200-400 lines/hour                            │
│                                                             │
│  AI-GENERATED CODE                                          │
│  ─────────────────                                          │
│  1. Disclose AI usage                                       │
│  2. Apply C.L.E.A.R. framework                              │
│  3. Extra scrutiny on security                              │
│  4. Verify you understand it                                │
│                                                             │
│  EXPERIMENT BRANCHES                                        │
│  ───────────────────                                        │
│  Branch: exp/{username}/{name}                              │
│  Register in experiment tracker                             │
│  Sync with main weekly                                      │
│  Full review only for production code                       │
│                                                             │
│  SLAs                                                       │
│  ────                                                       │
│  SHIP: Immediate (automated)                                │
│  SHOW: First response 24h, merge 48h                        │
│  ASK:  First response 4h, merge 24h                         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Appendix B: Sources and Further Reading

### Industry Research
- [Softr - 8 Vibe Coding Best Practices](https://www.softr.io/blog/vibe-coding-best-practices)
- [CodeRabbit - Code Review Best Practices for Vibe Coding](https://www.coderabbit.ai/blog/code-review-best-practices-for-vibe-coding)
- [Google Cloud - Vibe Coding Explained](https://cloud.google.com/discover/what-is-vibe-coding)
- [Qodo - Code Review Best Practices 2026](https://www.qodo.ai/blog/code-review-best-practices/)
- [Graphite - AI Code Review Implementation](https://graphite.com/guides/ai-code-review-implementation-best-practices)

### Bottleneck Solutions
- [The New Stack - AI That Codes Faster Than Humans Can Review](https://thenewstack.io/the-new-bottleneck-ai-that-codes-faster-than-humans-can-review/)
- [Async Squad - Code Review Bottleneck in AI Era](https://asyncsquadlabs.com/blog/code-review-bottleneck-ai-era/)
- [Better Software - From Bottleneck to Superpower](https://www.bettrsw.com/blogs/startup-guide-to-scalable-code-reviews)
- [Ship, Show, Ask Pattern](https://chemaclass.com/blog/ship-show-ask/)

### ML Engineering Practices
- [SE4ML - Code Review for Machine Learning](https://se4ml.org/software/chapter_cr.html)
- [Google ML - Managing ML Experiments](https://developers.google.com/machine-learning/managing-ml-projects/experiments)
- [Addy Osmani - LLM Coding Workflow 2026](https://addyosmani.com/blog/ai-coding-workflow/)

### Tools
- [CodeRabbit](https://coderabbit.ai)
- [Qodo](https://qodo.ai)
- [Graphite](https://graphite.dev)
- [Snyk](https://snyk.io)
- [SonarQube](https://sonarqube.org)

---

**Document Owner:** Engineering Team Lead
**Review Cycle:** Quarterly
**Next Review:** May 2026
