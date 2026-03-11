---
name: product-first-gate
description: Forces product-level thinking before code implementation. Use when any feature work, new component, or user-facing change is requested.
disable-model-invocation: false
---
# Product-First Gate

Before writing ANY code for a new feature or user-facing change:

## Step 1: Problem Definition (MANDATORY)
- What user problem does this solve?
- Who is the target user? What's their context?
- What does success look like from the user's perspective?

## Step 2: User Flow (MANDATORY)
- Map the user journey: entry point → actions → outcome
- Identify the happy path AND error states
- List every screen/state the user will see

## Step 3: Acceptance Criteria (MANDATORY)
- Write testable acceptance criteria for each flow
- Include edge cases and error handling
- Define "done" in user-observable terms

## Step 4: Design Direction (MANDATORY for UI work)
- Commit to a specific aesthetic direction
- Reference the project's design system tokens
- Sketch the component hierarchy before implementation

ONLY AFTER completing Steps 1-4 may you begin writing code.
Document all outputs in a feature-spec.md file before proceeding.
