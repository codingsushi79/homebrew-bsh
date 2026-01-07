# Autotype Homebrew Formula

This is a Homebrew formula for [hackertyper](https://github.com/scottjbarr/hackertyper), a CLI tool that simulates the effect of typing code like in movies where hackers are shown furiously typing.

## Installation

To install autotype using this formula:

```bash
brew install /path/to/autotype.rb
```

Or if you've added this to a tap:

```bash
brew install <tap-name>/autotype
```

## Usage

Once installed, you can run autotype:

```bash
autotype
```

The program will display simulated code as you type. You can adjust the typing speed with the `--delay` flag:

```bash
autotype --delay 50  # 50ms delay per character
```

## How it works

Autotype reads text from stdin and displays it character by character with configurable delays, simulating the effect of someone typing slowly. It's perfect for creating the illusion of being a meticulous coder in presentations, videos, or demonstrations.

For the classic "hacker" effect, pipe code or text files to it:

```bash
cat your_code.py | autotype --delay 50
```

This will display the content as if being typed character by character.

## Building from source

This formula builds hackertyper from the GitHub repository using Go. It requires Go 1.18+ to build.

## Publishing to Homebrew

To publish this formula to Homebrew, you have several options:

### Option 1: Create a Homebrew Tap (Recommended)

A tap is a GitHub repository containing Homebrew formulae. This is the easiest way to share your formula.

1. **Create a new GitHub repository** named `homebrew-<your-tap-name>` (e.g., `homebrew-autotype` or `homebrew-tools`)
   - The repository name must start with `homebrew-`
   - Make it public

2. **Add the formula to your tap:**
   ```bash
   # Clone your tap repository
   git clone https://github.com/<your-username>/homebrew-<tap-name>.git
   cd homebrew-<tap-name>
   
   # Copy your formula (must be in a Formula/ subdirectory)
   mkdir -p Formula
   cp /path/to/autotype.rb Formula/autotype.rb
   
   # Commit and push
   git add Formula/autotype.rb
   git commit -m "Add autotype formula"
   git push origin main
   ```

3. **Install from your tap:**
   ```bash
   brew tap <your-username>/<tap-name>
   brew install autotype
   ```

### Option 2: Submit to Homebrew Core

If you want to add this to the official Homebrew core repository:

1. **Fork the Homebrew repository:**
   ```bash
   git clone https://github.com/Homebrew/homebrew-core.git
   cd homebrew-core
   ```

2. **Add your formula:**
   ```bash
   cp /path/to/autotype.rb Formula/autotype.rb
   ```

3. **Test your formula:**
   ```bash
   brew install --build-from-source Formula/autotype.rb
   brew audit --strict Formula/autotype.rb
   brew test Formula/autotype.rb
   ```

4. **Commit and create a pull request:**
   ```bash
   git checkout -b add-autotype-formula
   git add Formula/autotype.rb
   git commit -m "autotype: add formula"
   git push origin add-autotype-formula
   ```
   Then create a PR on GitHub.

5. **Requirements for Homebrew Core:**
   - The upstream project must be actively maintained
   - The project should have at least 75 GitHub stars (or equivalent popularity)
   - The formula must pass all audits
   - The project should be useful to a significant number of users
   - See [Homebrew's Acceptable Formulae](https://docs.brew.sh/Acceptable-Formulae) for full requirements

### Option 3: Install from a URL

Users can install directly from a GitHub repository:

```bash
brew install <your-username>/<repo-name>/autotype.rb
```

Or from a raw GitHub URL:

```bash
brew install https://raw.githubusercontent.com/<your-username>/<repo-name>/main/autotype.rb
```

### Testing Your Formula

Before publishing, always test your formula:

```bash
# Install from local file
brew install --build-from-source /path/to/autotype.rb

# Run audits
brew audit --strict /path/to/autotype.rb

# Test the formula
brew test /path/to/autotype.rb

# Uninstall to test fresh install
brew uninstall autotype
```

### Updating the Formula

When you need to update the formula (e.g., new version):

1. Update the `version` and `revision` (or `tag`) in `autotype.rb`
2. Test the updated formula
3. Commit and push the changes to your tap or submit a PR to Homebrew core

### Formula Best Practices

- Keep the formula simple and maintainable
- Use stable URLs (tags/releases) when possible, not `HEAD`
- Include proper test blocks
- Follow Homebrew's style guide
- Keep dependencies minimal
- Document any special requirements

For more information, see the [Homebrew Formula Cookbook](https://docs.brew.sh/Formula-Cookbook).
