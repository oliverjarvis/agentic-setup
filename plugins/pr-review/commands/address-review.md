---
description: Read a PR's human review comments, push fixes, and resolve the threads
argument-hint: "[PR number] (defaults to the PR for the current branch)"
allowed-tools: Bash(gh:*), Bash(git:*), Edit, Write, Read
---

Address the human review feedback on a pull request end to end.

## 1. Identify the PR
Use `$1` if given, else the PR for the current branch:
```
gh pr view --json number,url,headRefName
```

## 2. Read the review threads
```
gh pr view <n> --comments
gh api repos/{owner}/{repo}/pulls/<n>/comments --paginate   # inline review comments
```
Fetch unresolved threads (with IDs) via GraphQL:
```
gh api graphql -f query='
  query($owner:String!,$repo:String!,$pr:Int!){
    repository(owner:$owner,name:$repo){
      pullRequest(number:$pr){
        reviewThreads(first:100){nodes{id isResolved path line
          comments(first:20){nodes{author{login} body}}}}}}}' \
  -F owner={owner} -F repo={repo} -F pr=<n>
```

## 3. Fix
For each actionable, unresolved thread: make the change in the code, keeping edits
minimal and scoped to the feedback. Group related fixes into clear commits.

## 4. Reply and resolve
Reply to a thread, then resolve it:
```
gh api repos/{owner}/{repo}/pulls/<n>/comments/<comment_id>/replies -f body="Fixed in <sha>."
gh api graphql -f query='mutation($id:ID!){resolveReviewThread(input:{threadId:$id}){thread{isResolved}}}' -F id=<thread_id>
```

## 5. Push
```
git push
```

## Rules
- Only resolve a thread once the fix is actually pushed.
- If a comment is a question or you disagree, reply to discuss instead of silently
  resolving; surface it to the user (see the `receiving-code-review` skill for how to
  evaluate feedback rather than blindly implement it).
- Summarize to the user: threads addressed, fixes pushed, anything left open.
