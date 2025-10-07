# Contributing to WALLIX Automation Showroom

Thank you for your interest in contributing to the WALLIX Automation Showroom project! This document provides guidelines and instructions for contributing.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How to Contribute](#how-to-contribute)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Testing Guidelines](#testing-guidelines)
- [Documentation](#documentation)
- [Security](#security)

## Code of Conduct

This project adheres to a code of conduct. By participating, you are expected to uphold this code. Please report unacceptable behavior to the project maintainers.

### Our Standards

- Be respectful and inclusive
- Welcome newcomers and help them learn
- Accept constructive criticism gracefully
- Focus on what is best for the community
- Show empathy towards others

## Getting Started

### Prerequisites

- Ansible 2.9+
- Python 3.6+
- Git
- A WALLIX Bastion for testing (or access to one)

### Initial Setup

1. **Fork the repository**

   ```bash
   # Fork on GitHub, then clone your fork
   git clone https://github.com/YOUR_USERNAME/Automation_Showroom.git
   cd Automation_Showroom/Ansible/Provisioning/Advanced
   ```

2. **Add upstream remote**

   ```bash
   git remote add upstream https://github.com/wallix/Automation_Showroom.git
   git fetch upstream
   ```

3. **Create development environment**

   ```bash
   # Install Ansible and dependencies
   pip install -r requirements.txt
   
   # Set up test inventory
   cp inventory/development.example inventory/development
   ```

## How to Contribute

### Types of Contributions

We welcome:

- **Bug fixes**: Fix issues in existing code
- **New features**: Add new roles, tasks, or playbooks
- **Documentation**: Improve guides, examples, or API docs
- **Tests**: Add or improve test coverage
- **Examples**: Contribute real-world usage examples

### Reporting Issues

Before creating an issue:

1. Check if the issue already exists
2. Include detailed reproduction steps
3. Provide environment details (Ansible version, Python version, WALLIX Bastion version)
4. Include relevant logs (sanitized of sensitive data!)

### Suggesting Features

1. Open an issue with the "enhancement" label
2. Describe the use case and benefit
3. Provide examples if possible
4. Be open to discussion and feedback

## Development Workflow

### 1. Create a Branch

```bash
# Update your fork
git checkout develop
git pull upstream develop

# Create feature branch
git checkout -b feature/my-new-feature

# Or for bug fixes
git checkout -b fix/issue-123
```

### Branch Naming Convention

- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation changes
- `test/` - Test additions/changes
- `refactor/` - Code refactoring

### 2. Make Changes

Follow our [coding standards](#coding-standards) and:

- Write clear, descriptive commit messages
- Keep commits focused and atomic
- Test your changes thoroughly
- Update documentation as needed

### 3. Commit Your Changes

```bash
# Stage changes
git add .

# Commit with descriptive message
git commit -m "feat: add support for RADIUS authentication

- Implement RADIUS authentication in wallix-domains role
- Add configuration examples
- Update documentation
- Add tests for RADIUS auth"
```

### Commit Message Format

```
<type>: <subject>

<body>

<footer>
```

**Types:**

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `test`: Adding tests
- `refactor`: Code refactoring
- `style`: Code style changes (formatting)
- `chore`: Maintenance tasks

### 4. Push and Create Pull Request

```bash
# Push to your fork
git push origin feature/my-new-feature

# Create PR on GitHub
```

### Pull Request Guidelines

- **Title**: Clear and descriptive
- **Description**: Explain what and why
- **Link issues**: Reference related issues
- **Screenshots**: Include if UI/output changes
- **Testing**: Describe how you tested
- **Checklist**: Complete the PR template checklist

## Coding Standards

### Ansible Playbook Standards

#### YAML Formatting

```yaml
---
# Always start with document separator
- name: Descriptive task name
  module_name:
    parameter: value
    another_parameter: value
  when: condition
  tags:
    - tag1
    - tag2
```

#### Best Practices

1. **Always name tasks**

   ```yaml
   - name: Create user account
     # Good
   
   - user:
     # Bad - no name
   ```

2. **Use YAML dictionary format**

   ```yaml
   # Good
   - name: Create directory
     file:
       path: /etc/wallix
       state: directory
       mode: '0755'
   
   # Avoid
   - name: Create directory
     file: path=/etc/wallix state=directory mode=0755
   ```

3. **Idempotency**
   - All tasks should be idempotent
   - Running twice should be safe
   - Use `changed_when` and `failed_when` appropriately

4. **Variables**
   - Use meaningful names: `wallix_api_host` not `host`
   - Prefix role variables: `rolename_variable`
   - Use snake_case for variables

5. **Security**
   - Never hardcode credentials
   - Always use Ansible Vault for secrets
   - Use `no_log: true` for sensitive tasks

#### Role Structure

```
roles/wallix-component/
├── defaults/
│   └── main.yml          # Default variables
├── tasks/
│   └── main.yml          # Main tasks
├── handlers/
│   └── main.yml          # Handlers
├── templates/
│   └── config.j2         # Jinja2 templates
├── files/
│   └── script.sh         # Static files
├── vars/
│   └── main.yml          # Role variables
├── meta/
│   └── main.yml          # Role metadata
└── README.md             # Role documentation
```

### Python Code Standards

Follow PEP 8:

```python
# Good
def calculate_api_timeout(base_timeout, retry_count):
    """Calculate total API timeout including retries."""
    return base_timeout * (retry_count + 1)

# Include docstrings
# Use descriptive names
# Follow 4-space indentation
```

### Documentation Standards

#### Markdown

- Use ATX-style headers (`#` not underlines)
- Include table of contents for long docs
- Use code blocks with language specified
- Include examples liberally

#### Comments

```yaml
# Explain WHY, not WHAT
- name: Retry API call on network failures
  # The bastion may be behind a load balancer causing intermittent failures
  uri:
    url: "{{ wallix_api_url }}"
  retries: 3
```

## Testing Guidelines

### Before Submitting

1. **Syntax check**

   ```bash
   ansible-playbook --syntax-check playbooks/your-playbook.yml
   ```

2. **Dry run**

   ```bash
   ansible-playbook -i inventory/development playbooks/your-playbook.yml \
     --check
   ```

3. **Test in development**

   ```bash
   ansible-playbook -i inventory/development playbooks/your-playbook.yml
   ```

### Test Coverage

- Test all new features
- Test edge cases
- Test error handling
- Verify idempotency

### Test Environments

- Development: For initial testing
- Staging: For integration testing
- Production: For final validation (with caution!)

## Documentation

### What to Document

1. **New features**: How to use them
2. **API changes**: Breaking changes especially
3. **Configuration**: New variables or settings
4. **Examples**: Real-world usage
5. **Troubleshooting**: Common issues

### Where to Document

- **README.md**: Overview and getting started
- **QUICKSTART.md**: Quick setup guide
- **Role README**: Specific role documentation
- **Code comments**: Complex logic
- **CHANGELOG.md**: Version changes

### Documentation Checklist

- [ ] Update README if needed
- [ ] Add role documentation
- [ ] Include usage examples
- [ ] Update CHANGELOG
- [ ] Check for broken links
- [ ] Verify code blocks work

## Security

### Security-First Approach

1. **Never commit secrets**
   - Check `.gitignore` is comprehensive
   - Use Ansible Vault for all credentials
   - Scan commits before pushing

2. **Sanitize examples**
   - Use placeholders: `example.com`, `192.0.2.1`
   - No real IPs or hostnames
   - Obvious fake credentials

3. **Report security issues privately**
   - Don't create public issues
   - Wait for security advisory

### Security Checklist

- [ ] No hardcoded credentials
- [ ] Vault files encrypted
- [ ] SSL verification enabled (except dev)
- [ ] Sensitive data uses `no_log: true`
- [ ] Examples use placeholders
- [ ] Dependencies are up to date

## Review Process

### What Reviewers Look For

1. **Functionality**: Does it work?
2. **Code quality**: Follows standards?
3. **Tests**: Adequately tested?
4. **Documentation**: Well documented?
5. **Security**: No vulnerabilities?
6. **Compatibility**: Works with supported versions?

### Responding to Feedback

- Be open to suggestions
- Ask questions if unclear
- Make requested changes promptly
- Thank reviewers for their time

### Changelog

Update `CHANGELOG.md`:

```markdown
## [1.2.0] - 2025-10-03

### Added
- RADIUS authentication support in wallix-domains role

### Changed
- Improved error handling in wallix-auth role

### Fixed
- Session cleanup now properly removes temporary files
```

## Getting Help

### Communication Channels

- **GitHub Issues**: Bug reports and features
- **Pull Requests**: Code discussions

### Resources

- [Ansible Documentation](https://docs.ansible.com/)
- [WALLIX API Documentation](https://doc.wallix.com/)
- [Project README](README.md)

## Recognition

Contributors will be recognized in:

- `CONTRIBUTORS.md` file
- Release notes
- Project documentation
- README.md contributors section (via all-contributors)

### Adding Contributors with all-contributors

This project uses [all-contributors](https://allcontributors.org/) to recognize all contributors, not just code contributors.

#### Adding a New Contributor

**Method 1: Using the all-contributors bot (Recommended)**

Comment on an issue or pull request:

```
@all-contributors please add @username for code, doc, example
```

Available contribution types:
- `code`: Code contributions
- `doc`: Documentation
- `example`: Examples
- `test`: Tests
- `ideas`: Ideas & planning
- `infra`: Infrastructure (CI/CD, build tools)
- `maintenance`: Maintenance
- `review`: Reviewing pull requests
- `question`: Answering questions
- `bug`: Bug reports
- `talk`: Talks/presentations
- `tutorial`: Tutorials

**Method 2: Using the CLI**

```bash
# Add a contributor
npx all-contributors add username code,doc

# Generate the contributors list
npx all-contributors generate
```

**Method 3: Manual editing**

1. Edit `.all-contributorsrc`:

```json
{
  "contributors": [
    {
      "login": "username",
      "name": "Full Name",
      "avatar_url": "https://avatars.githubusercontent.com/u/12345",
      "profile": "https://github.com/username",
      "contributions": [
        "code",
        "doc"
      ]
    }
  ]
}
```

2. Generate the table:

```bash
npx all-contributors generate
```

3. Commit the changes:

```bash
git add .all-contributorsrc README.md
git commit -m "docs: add @username as a contributor"
```

#### Contribution Types Guide

Choose the appropriate types for the contribution:

| Type | When to Use |
|------|-------------|
| `code` | Any code contributions (playbooks, roles, scripts) |
| `doc` | Documentation improvements (README, guides, comments) |
| `example` | Adding or improving examples |
| `test` | Adding or improving tests |
| `ideas` | Feature suggestions, architecture discussions |
| `infra` | CI/CD, GitHub Actions, build scripts |
| `review` | Reviewing PRs, providing feedback |
| `bug` | Filing detailed bug reports |
| `question` | Helping others in issues/discussions |

**Note:** Contributors are automatically added when their PR is merged if using the all-contributors bot.

Thank you for contributing! 🎉
