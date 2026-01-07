# Homebrew Installation Setup

This guide explains how to publish `bsh` to Homebrew so users can install it with `brew install`.

## Option 1: Create a Homebrew Tap (Recommended - Easiest)

### Step 1: Create the Tap Repository

1. Go to GitHub and create a new repository named `homebrew-bsh`
   - The name must start with `homebrew-`
   - Make it public
   - Don't initialize with README, .gitignore, or license

2. Clone the repository:
   ```bash
   git clone https://github.com/codingsushi79/homebrew-bsh.git
   cd homebrew-bsh
   ```

3. Copy the formula:
   ```bash
   mkdir -p Formula
   cp /path/to/bsh/Formula/bsh.rb Formula/bsh.rb
   ```

4. Update the formula to use a specific commit or tag:
   - For a specific commit: Replace `revision: "HEAD"` with `revision: "<commit-hash>"`
   - For a tag: Replace the `url` line with:
     ```ruby
     url "https://github.com/codingsushi79/bsh/archive/refs/tags/v1.0.0.tar.gz"
     sha256 "<sha256-hash>"
     ```
     Then remove the `revision:` line

5. Commit and push:
   ```bash
   git add Formula/bsh.rb
   git commit -m "Add bsh formula"
   git push origin main
   ```

### Step 2: Install from Your Tap

Users (including you) can now install bsh:

```bash
brew tap codingsushi79/bsh
brew install bsh
```

## Option 2: Submit to Homebrew Core (Official)

If you want to add this to the official Homebrew repository:

### Requirements:
- Repository must have at least 75 GitHub stars
- Project must be actively maintained
- Must have tagged releases
- Must pass all Homebrew audits

### Steps:

1. Fork [homebrew-core](https://github.com/Homebrew/homebrew-core)

2. Clone your fork:
   ```bash
   git clone https://github.com/<your-username>/homebrew-core.git
   cd homebrew-core
   ```

3. Copy the formula:
   ```bash
   cp /path/to/bsh/Formula/bsh.rb Formula/bsh.rb
   ```

4. Update the formula to use a tagged release:
   ```ruby
   url "https://github.com/codingsushi79/bsh/archive/refs/tags/v1.0.0.tar.gz"
   sha256 "<calculate-sha256>"
   ```

5. Test the formula:
   ```bash
   brew install --build-from-source Formula/bsh.rb
   brew audit --strict Formula/bsh.rb
   brew test Formula/bsh.rb
   ```

6. Create a pull request:
   ```bash
   git checkout -b add-bsh-formula
   git add Formula/bsh.rb
   git commit -m "bsh: add formula"
   git push origin add-bsh-formula
   ```
   Then create a PR on GitHub.

## Creating a Release Tag (Recommended)

For better versioning, create a Git tag:

```bash
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

Then update the formula to use the tag instead of a commit hash.

## Testing Your Formula Locally

Before publishing, test it:

```bash
# Install from local file
brew install --build-from-source /path/to/Formula/bsh.rb

# Run audits
brew audit --strict /path/to/Formula/bsh.rb

# Test the formula
brew test /path/to/Formula/bsh.rb

# Uninstall to test fresh install
brew uninstall bsh
```

## Updating the Formula

When you release a new version:

1. Create a new tag: `git tag -a v1.1.0 -m "Release 1.1.0"`
2. Update the formula's `version` and `url`/`revision`
3. Commit and push the changes

