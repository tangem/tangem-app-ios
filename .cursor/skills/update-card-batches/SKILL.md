---
name: update-card-batches
description: Update card batch IDs by fetching info from Jira, downloading assets from Figma, and updating the codebase
argument: jira_issue - Jira issue reference in the form [REDACTED_INFO] or just 12345
---

# Update Card Batches

This skill automates the process of adding new card batch IDs to the Tangem iOS app. It fetches batch information from Jira, downloads card images from Figma, adds them to the Xcode project, updates the code, and creates a pull request.

## Important Guidelines

**ALWAYS ASK THE USER when you encounter:**
- Ambiguous batch names or IDs in the Jira issue
- Multiple possible interpretations of the batch information
- Figma layers that don't match expected naming patterns
- Uncertainty about which assets to download
- Any step where the correct action is unclear

Use `AskUserQuestion` tool to clarify before proceeding. Never guess or make assumptions.

## Prerequisites

- Jira MCP configured and authenticated
- Figma MCP configured and authenticated
- GitHub MCP configured and authenticated
- Write access to the repository

## Steps

### 1. Parse Jira Issue Reference

Parse `$ARGUMENTS` to extract the Jira issue number:
- If input is just digits (e.g., `12345`), prefix with `IOS-`
- If input already has `IOS-` prefix (e.g., `[REDACTED_INFO]`), use as-is
- Store as `issue_key` (e.g., `[REDACTED_INFO]`)

### 2. Get Atlassian Cloud ID

Use `mcp__atlassian__getAccessibleAtlassianResources` to get the cloud ID for the Tangem Atlassian workspace.

### 3. Fetch Jira Issue Details

Use `mcp__atlassian__getJiraIssue` with:
- `cloudId`: from step 2
- `issueIdOrKey`: the `issue_key` from step 1

Extract from the issue:
- **Batch names**: Look for batch/card names in the description (e.g., "Lunar", "Winter Sakura", "Hyper Blue")
- **Batch IDs**: Look for batch IDs in format `AFXXXXX`, `AF990XXX`, or `BBXXXXXX` patterns
- **Summary/title**: For branch naming

Parse the issue description carefully to identify:
1. Card/batch name (human readable, e.g., "Lunar", "Blush Sky")
2. Associated batch IDs (e.g., `AF990057`, `AF990058`, `AF990059`)

**If the issue description is unclear or you cannot confidently identify batch names and IDs, ASK THE USER:**
- "I found these potential batch names: X, Y, Z. Which ones should I add?"
- "I found these batch IDs: A, B, C. Are these correct?"
- "The issue description doesn't clearly specify batch IDs. Can you provide them?"

### 4. Fetch Card Images from Figma

The card images are stored in the **Universal design library** Figma file.

**CRITICAL: Always export assets as PDF format. Never use screenshots.**

#### 4.1 Find the Figma File

Search for card assets in the following Figma's files:
- https://www.figma.com/design/FEmaalHfkdg07MH254kSgL/Universal-design-library?node-id=7-21212&t=r5CNTAV5sWKBhSxz-0
- https://www.figma.com/design/FEmaalHfkdg07MH254kSgL/Universal-design-library?node-id=7-23733&t=r5CNTAV5sWKBhSxz-4
The cards are typically named with patterns like `{BatchName}Double`, `{BatchName}Triple`

**If you cannot find the expected layer names, ASK THE USER for clarification before proceeding.**

#### 4.2 Export Card Assets as PDF

For each batch, you need TWO assets:
- `{BatchName}Double` - Image showing 2 cards (for `cardsCount == 2`)
- `{BatchName}Triple` - Image showing 3 cards (for `cardsCount == 3`)

**Export Process:**

1. Use `mcp__figma-remote-mcp__get_metadata` to explore the Cards section and find the correct node IDs for the batch assets.

2. Use `mcp__figma-remote-mcp__get_design_context` with the node IDs to get export URLs. Request PDF format export.

3. The response will include `downloadUrls` - use these to download the PDF files.

4. Download the PDF files using `curl` or similar:
   ```bash
   curl -o "{BatchName}Double.pdf" "<download_url>"
   curl -o "{BatchName}Triple.pdf" "<download_url>"
   ```

5. Move the downloaded PDFs to the appropriate asset directories.

**If PDF export is not available or fails, ASK THE USER how to proceed. Do not fall back to PNG/screenshot.**

### 5. Create Asset Directories and Files

For each batch (e.g., "Lunar"), create:

#### 5.1 Double Image Asset
Create directory: `Modules/TangemAssets/Assets/Assets.xcassets/Cards/{BatchName}Double.imageset/`

Create `Contents.json`:
```json
{
  "images" : [
    {
      "filename" : "{BatchName}Double.pdf",
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

Add the PDF file: `{BatchName}Double.pdf`

#### 5.2 Triple Image Asset
Create directory: `Modules/TangemAssets/Assets/Assets.xcassets/Cards/{BatchName}Triple.imageset/`

Create `Contents.json`:
```json
{
  "images" : [
    {
      "filename" : "{BatchName}Triple.pdf",
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

Add the PDF file: `{BatchName}Triple.pdf`

### 6. Run SwiftGen to Generate Asset Code

Run SwiftGen to regenerate the asset catalog code:

```bash
mint run swiftgen@6.6.3 config run --config swiftgen.yml
```

This will update `Modules/TangemAssets/Generated/Assets.swift` to include the new card images.

### 7. Update Wallet2Config.swift

Edit `Tangem/Domain/UserWalletModel/UserWalletConfig/Implementations/Wallet2Config.swift`.

In the `cardHeaderImage` computed property's switch statement, add a new case **before the `default:` case**:

```swift
        // {Batch Name}
        case "{BatchID1}", "{BatchID2}", "{BatchID3}":
            return cardsCount == 2 ? Assets.Cards.{batchName}Double : Assets.Cards.{batchName}Triple
```

**Naming conventions:**
- Swift asset name uses camelCase: `lunarDouble`, `winterSakuraDouble`
- Comment uses human-readable name: `// Lunar`, `// Winter Sakura`
- Batch IDs are quoted strings: `"AF990057"`, `"AF990058"`

**Example for "Hyper Blue" with batch IDs AF990026, AF990027, AF990028:**
```swift
        // Hyper Blue summer collection
        case "AF990026", "AF990027", "AF990028":
            return cardsCount == 2 ? Assets.Cards.hyperBlueDouble : Assets.Cards.hyperBlueTriple
```

### 8. Create Git Branch

Create a new branch from current HEAD:

```bash
git checkout -b feature/{issue_key}_update_{batch_name_snake_case}_batch_ids
```

Where:
- `{issue_key}` is the Jira issue (e.g., `[REDACTED_INFO]`)
- `{batch_name_snake_case}` is the batch name in snake_case (e.g., `summer`, `lunar`, `hyper_blue`)

### 9. Stage and Commit Changes

```bash
git add Modules/TangemAssets/Assets/Assets.xcassets/Cards/
git add Modules/TangemAssets/Generated/
git add Tangem/Domain/UserWalletModel/UserWalletConfig/Implementations/Wallet2Config.swift
git commit -m "{issue_key} Add {batch_name} batch ids

Co-Authored-By: Claude <noreply@anthropic.com>"
```

### 10. Push Branch

```bash
git push -u origin HEAD
```

### 11. Create Pull Request

Use the `/create-pr` skill or manually create the PR:

Use `mcp__github__create_pull_request` with:
- `owner`: `tangem-developments`
- `repo`: `tangem-app-ios`
- `title`: `{issue_key}: Add {batch_name} batch ids`
- `head`: branch name from step 8
- `base`: `develop`
- `body`:
  ```
  [{issue_key}](https://tangem.atlassian.net/browse/{issue_key})

  ## Summary
  - Added card images for {batch_name}
  - Added batch IDs: {list of batch IDs}

  ## Test plan
  - [ ] Verify card images display correctly in the app
  - [ ] Test with each batch ID
  ```

### 12. Report Results

Output:
- PR URL
- List of batch IDs added
- List of assets added
- Files modified

## Troubleshooting

**When in doubt, ALWAYS ask the user before proceeding.**

### Figma Assets Not Found
- Check the exact layer names in Figma - they should match `{BatchName}Double` and `{BatchName}Triple`
- The Universal design library structure may have changed - explore the file structure first
- **ASK THE USER** to provide the correct Figma file key or node IDs if standard navigation fails

### PDF Export Fails
- **Do NOT fall back to screenshots or PNG**
- **ASK THE USER** for alternative instructions or manual PDF files

### SwiftGen Fails
- Ensure `mint` is installed and swiftgen is available
- Check that asset names don't conflict with existing assets
- **ASK THE USER** if the asset naming convention should be different

### Build Errors After Changes
- Run `mint run swiftgen@6.6.3 config run --config swiftgen.yml` to regenerate assets
- Verify the asset names in Swift code match the generated `Assets.Cards.*` constants
- **ASK THE USER** for guidance if errors persist

## Reference

See PR https://github.com/tangem-developments/tangem-app-ios/pull/1545/ for a reference implementation of adding summer batch IDs.
