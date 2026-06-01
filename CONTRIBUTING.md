# Contributing to Network Doctor

Thank you for your interest in improving Network Doctor!

## How to Contribute

1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feature/amazing-feature`)
3. **Commit your changes** (`git commit -m 'Add some amazing feature'`)
4. **Push to the branch** (`git push origin feature/amazing-feature`)
5. **Open a Pull Request**

## Development Guidelines

- This project targets Windows PowerShell (5.1+) and PowerShell 7+.
- Keep the tool self-contained when possible (single-file scripts are preferred for easy distribution).
- Focus on practical diagnostics for real-world flaky cable connections (especially Rogers/Shaw Hitron gateways).
- Document any new features clearly.

## Reporting Issues

When reporting bugs or requesting features, please include:
- Your Windows version and PowerShell version
- The exact gateway model (e.g. Hitron CGM4331SHW)
- What the gateway LED was doing during the issue
- Any relevant log output from the tool

## Code Style

- Use clear, descriptive variable names
- Add comments for complex logic
- Keep the interactive menu style consistent
