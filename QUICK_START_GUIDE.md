# Quick Start Guide: Implementing the New Review Process

A step-by-step guide for team leads to roll out the new code review process.

---

## Week 1: Immediate Actions

### Day 1-2: Set Up Branch Protection

```bash
# Create experiment branch naming convention
# All experiment branches: exp/{username}/{experiment-name}

# GitHub CLI example for branch rules
gh api repos/{owner}/{repo}/rulesets -X POST -f name="experiment-branches" \
  -f target="branch" \
  -f enforcement="active" \
  -f "conditions[ref_name][include][]=refs/heads/exp/**" \
  -f "rules[][type]=deletion" \
  -f "bypass_actors[][actor_type]=OrganizationAdmin"
```

### Day 3-4: Configure Auto-Merge for SHIP Tier

Create `.github/workflows/auto-merge.yml`:

```yaml
name: Auto-merge SHIP tier

on:
  pull_request:
    types: [opened, synchronize, reopened]
    paths:
      - 'docs/**'
      - 'experiments/configs/**'
      - '*.md'
      - '.vscode/**'
      - 'notebooks/**/*.ipynb'

jobs:
  auto-merge:
    runs-on: ubuntu-latest
    if: github.actor != 'dependabot[bot]'
    steps:
      - uses: actions/checkout@v4

      - name: Run CI checks
        run: |
          # Your lint/test commands
          echo "Running CI checks..."

      - name: Enable auto-merge
        if: success()
        run: gh pr merge --auto --squash "$PR_URL"
        env:
          PR_URL: ${{ github.event.pull_request.html_url }}
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Day 5: Create PR Templates

Create `.github/PULL_REQUEST_TEMPLATE/ship.md`:
```markdown
## [SHIP] {title}

**Category:** Documentation / Config / Experiment

### Changes
-

### Checklist
- [ ] CI passes
- [ ] No production code changes
- [ ] Self-reviewed
```

Create `.github/PULL_REQUEST_TEMPLATE/show.md`:
```markdown
## [SHOW] {title}

**What:** Brief description of changes
**Why:** Reason for the change
**Risk:** Low / Medium

### Changes
-

### Testing
- [ ] Unit tests added/updated
- [ ] Manual testing completed

### AI Assistance
- [ ] No AI assistance used
- [ ] AI assisted: ___________
```

Create `.github/PULL_REQUEST_TEMPLATE/ask.md`:
```markdown
## [ASK] {title}

**What:** Detailed description
**Why:** Business/technical justification
**Risk:** Medium / High

### Changes
-

### Security Considerations
-

### Testing
- [ ] Unit tests
- [ ] Integration tests
- [ ] Manual testing
- [ ] Security review requested

### AI Assistance
- [ ] No AI assistance used
- [ ] AI assisted: ___________
  - [ ] All generated code reviewed and understood

### Rollback Plan
How to revert if issues arise:
```

---

## Week 2: Tooling Setup

### Install AI Code Review Tool

**Option A: CodeRabbit (Recommended)**
1. Go to [coderabbit.ai](https://coderabbit.ai)
2. Install GitHub App
3. Configure in `.coderabbit.yaml`:

```yaml
language: en
reviews:
  auto_review:
    enabled: true
    base_branches:
      - main
      - develop
  path_filters:
    exclude:
      - "docs/**"
      - "*.md"
      - "experiments/configs/**"
  review_profile: assertive
```

**Option B: Qodo**
1. Install VS Code extension
2. Configure team settings
3. Enable PR review integration

### Set Up Metrics Dashboard

Create a simple metrics tracking script:

```python
# scripts/review_metrics.py
import subprocess
import json
from datetime import datetime, timedelta

def get_pr_metrics(days=30):
    """Gather PR metrics for the past N days."""
    since = (datetime.now() - timedelta(days=days)).isoformat()

    # Get merged PRs
    result = subprocess.run([
        'gh', 'pr', 'list',
        '--state', 'merged',
        '--json', 'number,title,createdAt,mergedAt,additions,deletions,reviewDecision',
        '--limit', '100'
    ], capture_output=True, text=True)

    prs = json.loads(result.stdout)

    metrics = {
        'total_prs': len(prs),
        'avg_time_to_merge_hours': 0,
        'avg_size': 0,
        'large_prs': 0,  # > 400 lines
    }

    for pr in prs:
        created = datetime.fromisoformat(pr['createdAt'].replace('Z', '+00:00'))
        merged = datetime.fromisoformat(pr['mergedAt'].replace('Z', '+00:00'))
        hours = (merged - created).total_seconds() / 3600
        metrics['avg_time_to_merge_hours'] += hours

        size = pr['additions'] + pr['deletions']
        metrics['avg_size'] += size
        if size > 400:
            metrics['large_prs'] += 1

    if prs:
        metrics['avg_time_to_merge_hours'] /= len(prs)
        metrics['avg_size'] /= len(prs)

    return metrics

if __name__ == '__main__':
    metrics = get_pr_metrics()
    print(f"PRs merged: {metrics['total_prs']}")
    print(f"Avg time to merge: {metrics['avg_time_to_merge_hours']:.1f} hours")
    print(f"Avg PR size: {metrics['avg_size']:.0f} lines")
    print(f"Large PRs (>400 lines): {metrics['large_prs']}")
```

---

## Week 3: Team Communication

### Team Meeting Agenda

```markdown
## New Code Review Process - Team Meeting

### Overview (10 min)
- Why we're changing (bottleneck data)
- Three-tier system: SHIP / SHOW / ASK
- Experiment branch protocol

### Demos (20 min)
- Demo: Creating a SHIP tier PR (auto-merge)
- Demo: SHOW tier async workflow
- Demo: ASK tier full review
- Demo: Experiment branch registration

### AI Review Guidelines (10 min)
- AI disclosure requirement
- C.L.E.A.R. framework overview
- What humans still own

### Q&A (20 min)
- Address concerns
- Gather feedback
- Identify edge cases

### Action Items
- [ ] Everyone reads full guidelines doc
- [ ] Update personal workflows
- [ ] First week: tag PRs with tier
- [ ] Feedback session in 2 weeks
```

### Slack/Teams Announcement

```
:rocket: *New Code Review Process Live*

Starting [DATE], we're rolling out our updated code review process to unblock experimentation while maintaining quality.

*Key Changes:*
• *SHIP tier* - Docs, configs, experiments auto-merge after CI
• *SHOW tier* - Standard features get async review (24h)
• *ASK tier* - Production/security gets full review (4h response)

• *Experiment branches* - Work freely on `exp/your-name/experiment`
• *AI disclosure* - Note if you used Copilot/Claude in your PR

*Resources:*
• Full guidelines: [link to CODE_REVIEW_GUIDELINES.md]
• Checklists: [link to REVIEW_CHECKLISTS.md]
• Questions: Post in #engineering-process

Let's ship faster while keeping quality high! :zap:
```

---

## Week 4: Experiment Tracking Setup

### Create Experiment Registry

Create `experiments/registry/TEMPLATE.yaml`:

```yaml
# Copy this template for each new experiment
# Save as: experiments/registry/{experiment-id}.yaml

experiment:
  id: exp-YYYY-NNN  # e.g., exp-2026-001
  name: "Human readable experiment name"
  owner: "@github-username"
  branch: "exp/username/short-name"

  # What are you testing?
  hypothesis: |
    We believe that [change] will result in [outcome]
    because [reasoning].

  # Timeline
  start_date: YYYY-MM-DD
  expected_duration: "X days/weeks"

  # Resources
  resources:
    gpus: 0
    estimated_cost: "$0"
    compute_cluster: "cluster-name"

  # How will you know if it worked?
  success_criteria:
    - "Metric A > baseline by X%"
    - "No regression in metric B"

  # Current state
  status: planned  # planned | in_progress | completed | abandoned

  # Results (fill in when complete)
  results:
    outcome: null  # success | partial | failed
    summary: null
    artifacts:
      - url: null
        description: null
```

### Experiment Registration Script

Create `scripts/register_experiment.sh`:

```bash
#!/bin/bash

# Interactive experiment registration

echo "=== Experiment Registration ==="
read -p "Experiment name: " name
read -p "Your GitHub username: " username
read -p "Hypothesis (one line): " hypothesis
read -p "Expected duration: " duration
read -p "GPUs needed: " gpus
read -p "Estimated cost: " cost

# Generate ID
id="exp-$(date +%Y)-$(printf '%03d' $(ls experiments/registry/*.yaml 2>/dev/null | wc -l | tr -d ' '))"
branch="exp/${username}/$(echo $name | tr ' ' '-' | tr '[:upper:]' '[:lower:]')"
filename="experiments/registry/${id}.yaml"

cat > "$filename" << EOF
experiment:
  id: ${id}
  name: "${name}"
  owner: "@${username}"
  branch: "${branch}"
  hypothesis: "${hypothesis}"
  start_date: $(date +%Y-%m-%d)
  expected_duration: "${duration}"
  resources:
    gpus: ${gpus}
    estimated_cost: "${cost}"
  success_criteria:
    - "TBD"
  status: in_progress
EOF

echo ""
echo "Experiment registered: ${filename}"
echo "Branch name: ${branch}"
echo ""
echo "Next steps:"
echo "  1. git checkout -b ${branch}"
echo "  2. Start experimenting!"
echo "  3. Update ${filename} with results when done"
```

---

## Monitoring & Iteration

### Weekly Check-In Template

```markdown
## Review Process Health Check - Week of [DATE]

### Metrics
- PRs merged: ___
- Avg time to merge: ___ hours
- PRs by tier: SHIP ___ / SHOW ___ / ASK ___
- Review SLA breaches: ___
- Large PRs (>400 lines): ___

### What's Working
-

### Pain Points
-

### Adjustments for Next Week
-

### Team Feedback
-
```

### Monthly Review Meeting

```markdown
## Monthly Review Process Retrospective

### Metrics Trend (4 weeks)
| Week | PRs | Avg Merge Time | SLA Breaches |
|------|-----|----------------|--------------|
| 1    |     |                |              |
| 2    |     |                |              |
| 3    |     |                |              |
| 4    |     |                |              |

### Tier Distribution
- SHIP: ___% (target: 20-30%)
- SHOW: ___% (target: 50-60%)
- ASK:  ___% (target: 20-30%)

### Discussion Topics
1. Are tier thresholds right?
2. Is AI review adding value?
3. Experiment branch protocol working?
4. Any security concerns?

### Action Items
- [ ]
```

---

## Troubleshooting

### "Too many PRs in ASK tier"

**Symptoms:** Most PRs require full review, defeating the purpose

**Solutions:**
1. Review tier classification criteria - may be too strict
2. Train team on when SHOW is appropriate
3. Add more paths to auto-merge whitelist
4. Consider domain-based rules (test files → SHOW)

### "Reviews still taking too long"

**Symptoms:** SLAs being missed despite new process

**Solutions:**
1. Check reviewer load distribution
2. Implement reviewer rotation
3. Add more backup reviewers
4. Consider pairing for complex reviews
5. Break down large PRs

### "AI review is noisy"

**Symptoms:** Too many false positives, team ignoring AI comments

**Solutions:**
1. Tune AI review configuration
2. Exclude certain file patterns
3. Adjust severity thresholds
4. Create team-specific rules
5. Provide feedback to AI tool vendor

### "Experiment branches diverging too much"

**Symptoms:** Massive merge conflicts when experiments complete

**Solutions:**
1. Enforce weekly main → experiment merges
2. Create automated sync workflow
3. Set branch age limits
4. Regular check-ins on long experiments

---

## Success Criteria

After 1 month, you should see:

- [ ] 30%+ reduction in time-to-merge for non-critical PRs
- [ ] Zero blocking on experiment work due to review
- [ ] Clear tier distribution (not everything in ASK)
- [ ] AI review catching routine issues
- [ ] Team comfortable with new process
- [ ] Metrics being tracked and reviewed

---

**Questions?** Reach out to the engineering process team or post in #engineering-process.
