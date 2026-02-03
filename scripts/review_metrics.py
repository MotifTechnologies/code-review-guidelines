#!/usr/bin/env python3
"""
Review Metrics Tracker

Tracks and reports PR review metrics using GitHub CLI.
Metrics include:
- Average time to merge
- Average PR size (lines changed)
- Average number of review cycles
- PR throughput by tier
"""

import json
import subprocess
import sys
from datetime import datetime, timedelta
from collections import defaultdict
from typing import List, Dict, Any


def run_gh_command(args: List[str]) -> str:
    """Run a GitHub CLI command and return output."""
    try:
        result = subprocess.run(
            ['gh'] + args,
            capture_output=True,
            text=True,
            check=True
        )
        return result.stdout
    except subprocess.CalledProcessError as e:
        print(f"Error running gh command: {e}", file=sys.stderr)
        print(f"Error output: {e.stderr}", file=sys.stderr)
        sys.exit(1)
    except FileNotFoundError:
        print("Error: GitHub CLI (gh) not found. Please install it first.", file=sys.stderr)
        print("Visit: https://cli.github.com/", file=sys.stderr)
        sys.exit(1)


def get_merged_prs(days: int = 30) -> List[Dict[str, Any]]:
    """Get all merged PRs from the last N days."""
    since_date = (datetime.now() - timedelta(days=days)).strftime('%Y-%m-%d')

    # Get merged PRs with JSON output
    output = run_gh_command([
        'pr', 'list',
        '--state', 'merged',
        '--limit', '1000',
        '--json', 'number,title,labels,createdAt,mergedAt,additions,deletions,reviews'
    ])

    prs = json.loads(output)

    # Filter by date
    filtered_prs = []
    for pr in prs:
        created_at = datetime.fromisoformat(pr['createdAt'].replace('Z', '+00:00'))
        if created_at >= datetime.now().replace(tzinfo=created_at.tzinfo) - timedelta(days=days):
            filtered_prs.append(pr)

    return filtered_prs


def calculate_time_to_merge(pr: Dict[str, Any]) -> float:
    """Calculate time from creation to merge in hours."""
    created_at = datetime.fromisoformat(pr['createdAt'].replace('Z', '+00:00'))
    merged_at = datetime.fromisoformat(pr['mergedAt'].replace('Z', '+00:00'))
    delta = merged_at - created_at
    return delta.total_seconds() / 3600  # Convert to hours


def get_pr_size(pr: Dict[str, Any]) -> int:
    """Get total lines changed in PR."""
    return pr.get('additions', 0) + pr.get('deletions', 0)


def count_review_cycles(pr: Dict[str, Any]) -> int:
    """Count number of review cycles (reviews + review comments)."""
    reviews = pr.get('reviews', [])
    if not reviews:
        return 0

    # Count unique review events (not including subsequent comments on same review)
    review_states = [r['state'] for r in reviews if r['state'] in ['CHANGES_REQUESTED', 'APPROVED', 'COMMENTED']]
    return len(review_states)


def get_tier(pr: Dict[str, Any]) -> str:
    """Extract tier from PR labels."""
    labels = pr.get('labels', [])
    for label in labels:
        label_name = label.get('name', '')
        if label_name in ['SHIP', 'CRUISE', 'RAFT', 'ANCHOR']:
            return label_name
    return 'UNTIERED'


def main():
    """Main function to generate review metrics report."""
    print("📊 Fetching PR review metrics...\n")

    # Get PRs from last 30 days
    prs = get_merged_prs(days=30)

    if not prs:
        print("No merged PRs found in the last 30 days.")
        return

    print(f"Found {len(prs)} merged PRs in the last 30 days\n")

    # Calculate metrics
    metrics_by_tier = defaultdict(lambda: {
        'count': 0,
        'total_time': 0,
        'total_size': 0,
        'total_reviews': 0
    })

    all_times = []
    all_sizes = []
    all_reviews = []

    for pr in prs:
        tier = get_tier(pr)
        time_to_merge = calculate_time_to_merge(pr)
        pr_size = get_pr_size(pr)
        review_cycles = count_review_cycles(pr)

        # Update tier-specific metrics
        metrics_by_tier[tier]['count'] += 1
        metrics_by_tier[tier]['total_time'] += time_to_merge
        metrics_by_tier[tier]['total_size'] += pr_size
        metrics_by_tier[tier]['total_reviews'] += review_cycles

        # Update overall metrics
        all_times.append(time_to_merge)
        all_sizes.append(pr_size)
        all_reviews.append(review_cycles)

    # Print overall metrics
    print("=" * 60)
    print("OVERALL METRICS (Last 30 Days)")
    print("=" * 60)
    print(f"Total PRs merged: {len(prs)}")
    print(f"Average time to merge: {sum(all_times) / len(all_times):.1f} hours")
    print(f"Average PR size: {sum(all_sizes) / len(all_sizes):.0f} lines changed")
    print(f"Average review cycles: {sum(all_reviews) / len(all_reviews):.1f}")
    print()

    # Print tier-specific metrics
    print("=" * 60)
    print("METRICS BY TIER")
    print("=" * 60)

    tier_order = ['SHIP', 'CRUISE', 'RAFT', 'ANCHOR', 'UNTIERED']
    for tier in tier_order:
        if tier not in metrics_by_tier:
            continue

        metrics = metrics_by_tier[tier]
        count = metrics['count']

        if count == 0:
            continue

        avg_time = metrics['total_time'] / count
        avg_size = metrics['total_size'] / count
        avg_reviews = metrics['total_reviews'] / count

        print(f"\n{tier}:")
        print(f"  PRs merged: {count}")
        print(f"  Avg time to merge: {avg_time:.1f} hours ({avg_time/24:.1f} days)")
        print(f"  Avg PR size: {avg_size:.0f} lines")
        print(f"  Avg review cycles: {avg_reviews:.1f}")

    # Print velocity metrics
    print("\n" + "=" * 60)
    print("VELOCITY METRICS")
    print("=" * 60)
    prs_per_week = len(prs) * 7 / 30
    print(f"PRs per week: {prs_per_week:.1f}")
    print(f"Lines changed per week: {sum(all_sizes) * 7 / 30:.0f}")

    # Print distribution
    print("\n" + "=" * 60)
    print("TIER DISTRIBUTION")
    print("=" * 60)
    for tier in tier_order:
        if tier in metrics_by_tier:
            count = metrics_by_tier[tier]['count']
            percentage = (count / len(prs)) * 100
            print(f"{tier}: {count} ({percentage:.1f}%)")


if __name__ == '__main__':
    main()
