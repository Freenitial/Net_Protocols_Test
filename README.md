
## **Net Protocols Test**

 Description
|                           ---                         |
|                                                       |
|   **Test Multiple Network Protocols Easily**          |
|                                                       |
|   Optional: call with arguments to replace the default config  |

--------------------

### Features ✨ 

- 🌍 Testing various protocols
- 📊 Visual table summary with progress in real time
- ✅ Debugging information for failed tests
- 🚀 Support multiple websites and rules at the same time

--------------------  

### Supported Arguments 🛠️

| **Argument** | **Value(s)**                              | **Description**                                       |
|--------------|-------------------------------------------|-------------------------------------------------------|
| `/site`      | domain[+++/---protocol]                  | Specifies target websites (with optional filters).    |
| `/only`      | ip4, ip6, tr4, tr6, tls, htp, dns        | Tests only the specified protocols.                  |
| `/exclude`   | ip4, ip6, tr4, tr6, tls, htp, dns        | Excludes specified protocols.                        |
| `/debug`     | true/false (default: true)               | Shows debug information for failed tests.            |
| `/nopause`   | true/false (default: false)              | Skips pause at the end of the script.                |

--------------------

### Supported Protocols

| **Protocol** | **Description**                           |
|--------------|-------------------------------------------|
| `ip4`        | Ping IPv4                                |
| `ip6`        | Ping IPv6                                |
| `tr4`        | Traceroute IPv4                          |
| `tr6`        | Traceroute IPv6                          |
| `tls`        | TLS 1.2 handshake                        |
| `htp`        | HTTPS connectivity                       |
| `dns`        | DNS resolution using `nslookup`          |

--------------------

### How to Use 📘

```
Basic Usage:
Net_Protocols_Test.bat /site google.com microsoft.com yahoo.com
- Tests all protocols for the provided sites.

Test Only Specific Protocols:
Net_Protocols_Test.bat /site google.com /only ip4 ip6
- Tests only IPv4 and IPv6 protocols.

Exclude Specific Protocols:
Net_Protocols_Test.bat /site google.com /exclude ip4 ip6
- Excludes IPv4 and IPv6 tests.

Advanced Usage: Include or Exclude Protocols Per Site:
Net_Protocols_Test.bat /site google.com+++ip4+++ip6 microsoft.com yahoo.com /exclude ip4 ip6
- Includes IPv4 and IPv6 for `google.com`.
- Excludes IPv4 and IPv6 for `microsoft.com` and `yahoo.com`.

Debug and No-Pause Mode:
Net_Protocols_Test.bat /site google.com /debug false /nopause true
- Disables debug output and skips the pause at the end of the script.
```

#### Notes:
- **Site Formatting:** Provide simple website addresses without special characters like `%`.
- **Protocol Rules:**
  - `+++protocol` overrides global exclusions for a specific protocol on a site.
  - `---protocol` excludes a specific protocol for a site.

--------------------

### Return Codes 📋

| **Code** | **Meaning**                                      |
|----------|--------------------------------------------------|
| `1`      | Unexpected error                                 |
| `2`      | Argument not recognized                          |
| `3`      | Failed test: Ping IPv4                           |
| `4`      | Failed test: Ping IPv6                           |
| `5`      | Failed test: Traceroute IPv4                    |
| `6`      | Failed test: Traceroute IPv6                    |
| `7`      | Failed test: TLS handshake                      |
| `8`      | Failed test: HTTPS connectivity                 |
| `9`      | Failed test: DNS resolution                     |
| `11`     | Failed to create output directory               |

--------------------

### Outputs 📂

- **Symbols in the table:**
  - `/` : Test in progress
  - `>` : Test skipped
  - `OK` : Test passed
  - `KO` : Test failed
- Debug files for failed tests are saved in the output directory.

--------------------

Feel free to contribute or report issues.
