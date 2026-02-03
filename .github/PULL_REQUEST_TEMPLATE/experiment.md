## [EXPERIMENT] Post-Experiment Results: <!-- Experiment name -->

**Original Experiment PR:** #<!-- Link to original SHIP experiment PR -->

---

## Experiment Summary

**Hypothesis:**
<!-- What were we testing? What did we expect to happen? -->

**Duration:** <!-- How long did the experiment run? -->

**Environment:** <!-- Where was this tested? Production/Staging/Canary? -->

---

## Results

### Key Metrics

| Metric | Baseline | Experiment | Change | Target Met? |
|--------|----------|------------|--------|-------------|
| <!-- e.g., Response Time --> | <!-- e.g., 250ms --> | <!-- e.g., 180ms --> | <!-- -28% --> | ✅ / ❌ |
| <!-- Metric 2 --> | | | | |
| <!-- Metric 3 --> | | | | |

### Qualitative Findings

<!-- Describe any unexpected behaviors, user feedback, or observations -->

---

## Decision

- [ ] **KEEP** - Merge experiment code to production
- [ ] **DISCARD** - Revert experiment and close
- [ ] **ITERATE** - Needs more experimentation

**Rationale:**
<!-- Explain the decision based on results -->

---

## Code Changes

### To Keep

<!-- List files/features that should be retained -->

- `path/to/file.ts` - <!-- Why this is valuable -->
- `path/to/another.ts` - <!-- Explanation -->

### To Discard

<!-- List experiment scaffolding, temporary code, or failed approaches -->

- `path/to/temporary.ts` - <!-- Why this should be removed -->
- `experiments/` - <!-- Cleanup needed -->

### To Refactor

<!-- Code that worked but needs productionization -->

- `path/to/prototype.ts` - <!-- What needs to change for production -->

---

## Production Path

If keeping this experiment, complete the following:

- [ ] Remove experiment flags/feature toggles
- [ ] Clean up temporary logging/debugging code
- [ ] Add comprehensive tests (currently: <!-- % coverage -->)
- [ ] Update documentation
- [ ] Add monitoring/alerting
- [ ] Performance optimization (if needed)
- [ ] Security review completed
- [ ] Accessibility review (if UI changes)

**Remaining Work:**
<!-- List any tasks needed to productionize this code -->

---

## Testing

### Experiment Testing
- [ ] A/B test results analyzed
- [ ] Statistical significance verified
- [ ] Edge cases observed
- [ ] Performance impact measured

### Production Testing (if keeping)
- [ ] Unit tests added/updated
- [ ] Integration tests added
- [ ] Manual testing in staging
- [ ] Load testing completed (if applicable)

---

## Rollout Plan (if keeping)

**Rollout Strategy:**
- [ ] Gradual rollout (canary → 10% → 50% → 100%)
- [ ] Feature flag controlled
- [ ] Immediate full rollout
- [ ] Other: <!-- Describe -->

**Monitoring:**
<!-- What metrics to watch during rollout -->

**Rollback Criteria:**
<!-- Under what conditions should this be rolled back? -->

---

## Learnings

### What Worked Well
<!-- Positive findings that inform future work -->

### What Didn't Work
<!-- Failed approaches and why -->

### Surprises
<!-- Unexpected results or insights -->

### Recommendations
<!-- Suggestions for future experiments or improvements -->

---

## AI Assistance

- [ ] AI tools were used in this experiment or analysis

**Tools used:** <!-- e.g., GitHub Copilot, Claude, ChatGPT -->

**Extent:** <!-- How AI was used in experimentation or analysis -->

---

## Additional Context

<!-- Screenshots, graphs, logs, related docs, etc. -->

---

**Review Notes:** If keeping experiment code, this PR should be re-tiered as SHOW or ASK based on the production risk level. See [REVIEW_CHECKLISTS.md](../REVIEW_CHECKLISTS.md) for appropriate review tier.
