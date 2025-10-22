# Local octo.nvim Fork

This directory contains a patched version of octo.nvim's GraphQL queries to fix the deprecated Projects (classic) warning.

## Changes

- **Removed `projectCards` queries** from `pull_request` and `issue` GraphQL queries
- **Removed `fragments.project_cards`** from fragment concatenations
- This eliminates the deprecation warning: `gh: Projects (classic) is being deprecated in favor of the new Projects experience`

## Files Modified

- `lua/octo/gh/queries.lua` - Removed all references to `projectCards` (classic projects)

## Why This Fork?

When `default_to_projects_v2 = true` is set, octo.nvim should only use Projects v2 APIs, but the original code still queries `projectCards` (classic projects), which triggers the GitHub CLI deprecation warning.

This fork removes those queries entirely since we're using Projects v2.

## Upstream

Based on: https://github.com/pwntester/octo.nvim

## Future

If/when this is fixed upstream, we can remove this fork and use the official version.
