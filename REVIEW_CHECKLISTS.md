# Code Review Checklists

Quick reference checklists for reviewers. Print or bookmark for daily use.

---

## PR Tier Classification Flowchart

```
                    ┌─────────────────┐
                    │   New PR Filed  │
                    └────────┬────────┘
                             │
                             ▼
              ┌──────────────────────────────┐
              │  Does it touch production    │
              │  code, security, or APIs?    │
              └──────────────┬───────────────┘
                             │
                    ┌────────┴────────┐
                    │                 │
                   YES               NO
                    │                 │
                    ▼                 ▼
              ┌──────────┐    ┌──────────────────┐
              │   ASK    │    │ Is it docs/config│
              │ Tier 3   │    │ /experiments?    │
              └──────────┘    └────────┬─────────┘
                                       │
                              ┌────────┴────────┐
                              │                 │
                             YES               NO
                              │                 │
                              ▼                 ▼
                        ┌──────────┐     ┌──────────┐
                        │   SHIP   │     │   SHOW   │
                        │  Tier 1  │     │  Tier 2  │
                        └──────────┘     └──────────┘
```

---

## Checklist: SHIP Tier (Auto-Merge)

**Use for:** Documentation, experiment configs, dev environment

```markdown
## SHIP Verification (Automated)

- [ ] CI pipeline passes
- [ ] No production code changes detected
- [ ] No security-sensitive file changes
- [ ] Linting passes
- [ ] Type checks pass

If all pass → Auto-merge enabled
```

---

## Checklist: SHOW Tier (Async Review)

**Use for:** Standard features, non-critical bug fixes, refactoring

```markdown
## SHOW Review Checklist

### Before Merging (Author)
- [ ] CI passes completely
- [ ] Self-reviewed the diff
- [ ] Tests added/updated for changes
- [ ] No TODOs left unaddressed
- [ ] PR description explains what and why

### Async Review (Reviewer - within 24h)
- [ ] Changes match PR description
- [ ] Logic appears correct
- [ ] No obvious security issues
- [ ] Tests are meaningful
- [ ] Code follows team patterns

### If Issues Found
- [ ] Comment on PR
- [ ] Author addresses in follow-up PR
- [ ] No need to block/revert unless critical
```

---

## Checklist: ASK Tier (Full Review)

**Use for:** Production pipelines, security, architecture, APIs

```markdown
## ASK Review Checklist

### Functionality
- [ ] Meets all stated requirements
- [ ] Edge cases are handled
- [ ] Error handling is comprehensive
- [ ] Failure modes are graceful

### Architecture
- [ ] Fits existing system design
- [ ] No unnecessary complexity
- [ ] Dependencies are appropriate
- [ ] Interfaces are clean

### Security
- [ ] Input validation present
- [ ] No credential/secret exposure
- [ ] Authorization checks in place
- [ ] SQL injection prevention
- [ ] XSS prevention (if applicable)
- [ ] OWASP top 10 considered

### Performance
- [ ] No obvious N+1 queries
- [ ] Memory usage is reasonable
- [ ] Scales with expected load
- [ ] No blocking operations in hot paths

### Testing
- [ ] Unit tests for new logic
- [ ] Integration tests for flows
- [ ] Edge cases tested
- [ ] Error paths tested
- [ ] Coverage is adequate

### Maintainability
- [ ] Code is readable
- [ ] Comments explain "why" not "what"
- [ ] Documentation updated
- [ ] Breaking changes documented

### ML-Specific (if applicable)
- [ ] Model versioning in place
- [ ] Fallback behavior defined
- [ ] Monitoring/alerting hooks
- [ ] Resource usage acceptable
- [ ] Reproducibility maintained
```

---

## Checklist: AI-Generated Code (C.L.E.A.R.)

**Use for:** Any code generated with AI assistance (Copilot, Claude, Cursor)

```markdown
## C.L.E.A.R. Review for AI-Generated Code

### C - Context
- [ ] Original prompt/requirement is clear
- [ ] Generation history understood (iterations?)
- [ ] AI assistance disclosed in PR

### L - Logic
- [ ] Logic is actually correct (don't trust formatting)
- [ ] Edge cases handled (AI often misses these)
- [ ] Error handling is comprehensive
- [ ] No placeholder/TODO code left behind

### E - Environment
- [ ] Fits existing architecture patterns
- [ ] Uses team's established libraries
- [ ] Consistent with codebase style
- [ ] Dependencies are real (not hallucinated)

### A - Assurance
- [ ] Tests actually test the right things
- [ ] Security review completed (extra scrutiny!)
- [ ] Performance is acceptable
- [ ] Input validation present

### R - Readability
- [ ] Team can maintain this code
- [ ] Author can explain every line
- [ ] Documentation is accurate
- [ ] No over-engineering

### AI-Specific Red Flags
- [ ] Check for hallucinated APIs/methods
- [ ] Check for subtle copy-paste bugs
- [ ] Check for overly complex solutions
- [ ] Check for missing null checks
- [ ] Check for hardcoded values that should be config
```

---

## Checklist: Experiment Code

**Use for:** Training scripts, experiment configs, research code

```markdown
## Experiment Code Review (Lighter Standard)

### Must Have
- [ ] Code runs without crashing
- [ ] No hardcoded credentials/secrets
- [ ] Resource cleanup on failure
- [ ] Basic logging present

### Reproducibility
- [ ] Random seeds documented
- [ ] Dependencies pinned (requirements.txt/pyproject.toml)
- [ ] Data version specified
- [ ] Hyperparameters logged

### Resource Management
- [ ] GPU memory usage reasonable
- [ ] Checkpointing for long runs
- [ ] Won't monopolize shared resources

### Tracking
- [ ] Logged to experiment tracker (W&B, MLflow, etc.)
- [ ] Metrics captured
- [ ] Artifacts versioned

### Nice to Have (don't block on these)
- [ ] Clean code structure
- [ ] Comprehensive tests
- [ ] Full documentation
```

---

## Checklist: Post-Experiment PR

**Use for:** When experiment code becomes production candidate

```markdown
## Post-Experiment PR Review

### Experiment Validation
- [ ] Hypothesis and results documented
- [ ] Metrics vs baseline provided
- [ ] Artifacts linked (models, logs)
- [ ] Success criteria evaluated

### Code Selection
- [ ] Clear list of code to keep vs discard
- [ ] Rationale for each file
- [ ] No dead experiment code included

### Production Readiness
- [ ] Code refactored to production standards
- [ ] Comprehensive tests added
- [ ] Documentation complete
- [ ] Error handling robust
- [ ] Monitoring hooks added

### Path Forward
- [ ] Production effort estimated
- [ ] Dependencies identified
- [ ] Rollout plan drafted
```

---

## Checklist: Security-Sensitive Changes

**Use for:** Auth, payments, PII handling, external APIs

```markdown
## Security Review Checklist

### Authentication & Authorization
- [ ] Auth required where needed
- [ ] Authorization checks on all endpoints
- [ ] Session management secure
- [ ] Token handling correct

### Data Protection
- [ ] PII properly handled
- [ ] Encryption at rest (if required)
- [ ] Encryption in transit
- [ ] Data retention policies followed

### Input Handling
- [ ] All inputs validated
- [ ] SQL injection prevented
- [ ] XSS prevented
- [ ] Command injection prevented
- [ ] Path traversal prevented

### Output Handling
- [ ] No sensitive data in logs
- [ ] Error messages don't leak info
- [ ] Response headers secure

### Dependencies
- [ ] No known vulnerabilities
- [ ] Minimal permissions granted
- [ ] Third-party audit considered

### Secrets
- [ ] No hardcoded secrets
- [ ] Secrets in secure store
- [ ] Rotation possible
```

---

## Quick Reference: Review Time Targets

| PR Type | First Response | Completion |
|---------|----------------|------------|
| SHIP | Automated | Immediate |
| SHOW | 24 hours | 48 hours |
| ASK | 4 hours | 24 hours |
| Security | 2 hours | 8 hours |

---

## Quick Reference: PR Size Guidance

| Lines Changed | Action |
|---------------|--------|
| < 100 | Easy review, fast turnaround |
| 100-400 | Ideal size, thorough review |
| 400-800 | Large, consider splitting |
| > 800 | Too large, must split |

**Review pace:** 200-400 lines per hour for quality review

---

## Reviewer Assignment Quick Guide

**Who should review?**

| Change Type | Primary Reviewer | Secondary |
|-------------|------------------|-----------|
| Feature code | Team member | Tech lead |
| Architecture | Tech lead | Senior engineer |
| Security | Security champion | Tech lead |
| ML/Training | ML engineer | Team member |
| Infra/DevOps | Platform engineer | Tech lead |
| Experiment | Any team member | Optional |

---

## Escalation Path

```
PR waiting > SLA time
        │
        ▼
Slack/Teams ping to reviewer
        │
        ▼ (no response in 2h)
Escalate to backup reviewer
        │
        ▼ (no response in 4h)
Escalate to team lead
        │
        ▼ (critical/blocking)
Escalate to engineering manager
```

---

**Tip:** Bookmark this page or print the relevant checklist for your review session.
