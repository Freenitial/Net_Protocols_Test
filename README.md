
# Net Protocols Test

**Test Multiple Network Protocols Easily**


![gif](https://github.com/user-attachments/assets/9b1d6ba1-3a2d-4f81-afe2-aa0df5c3bc83)

---

## Features ✨ 

- 🌍 Testing various protocols
- 📊 Visual table summary with progress in real time
- ✅ Debugging information for failed tests
- 🚀 Support multiple websites and rules at the same time

---

## Supported Arguments 🛠️

`/site` is **required** if you don't pre-fill the variable `set "sites="` at the top of the script.

⚠️ **Site Formatting:** Provide simple website addresses without special characters like `%` or `()`.

| **Argument**     | **Value(s)**                              | **Description**                                                   |
|------------------|-------------------------------------------|-------------------------------------------------------------------|
| **`/site`**      | `domain`[`+++`/`---` `protocol`]          | Specifies target websites (with optionnal added `+++`/`---` rules)|
| **`/only`**      | `ip4` `ip6` `tr4` `tr6` `tls` `htp` `dns` | Tests only the specified protocols                                |
| **`/exclude`**   | `ip4` `ip6` `tr4` `tr6` `tls` `htp` `dns` | Excludes specified protocols                                      |
| **`/nodebug`**   | `true` `false`  (default: `false`)        | Do not show debug information for failed tests                    |
| **`/nopause`**   | `true` `false`  (default: `false`)        | Do not pause at the end of the script                             |
| **`/output`**    | `C:\Path\to\logs\directory`               | Specifies output directory for logs (default: current directory)  |

---

## Supported Protocols and return codes 🌍

| **Return Code** | **Protocol** | **Return Code Description**                      |
|-----------------|--------------|--------------------------------------------------|
| `1`             |              | Unexpected error                                 |
| `2`             |              | Argument not recognized                          |
| **`3`**         |   `ip4`      | Failed test: Ping IPv4                           |
| **`4`**         |   `ip6`      | Failed test: Ping IPv6                           |
| **`5`**         |   `tr4`      | Failed test: Traceroute IPv4                     |
| **`6`**         |   `tr6`      | Failed test: Traceroute IPv6                     |
| **`7`**         |   `tls`      | Failed test: TLS handshake                       |
| **`8`**         |   `htp`      | Failed test: HTTPS connectivity                  |
| **`9`**         |   `dns`      | Failed test: DNS resolution                      |
| **`11`**        |              | Failed to create output directory                |


**Return codes will be combined in case of multiple Failed tests.**

**For example, in case of `Fail IPv4` + `Fail DNS`, return code will be `39`**

---


## How to Use 📘

```
🟢 TESTING MULTIPLE SITES
---------------------------------------
   ⚙️ Command:
       Net_Protocols_Test.bat /site google.com microsoft.com yahoo.com

   📖 Description:
       - Tests all supported protocols: IPv4, IPv6, Traceroute, TLS, HTTPS, and DNS 
         for the specified sites.


🟢 TESTING SPECIFIC PROTOCOLS (GLOBAL)
---------------------------------------
   ⚙️ Command:
       Net_Protocols_Test.bat /site google.com /only ip4 ip6

   📖 Description:
       - Runs tests only for IPv4 and IPv6 protocols.
       - ⚠️ `/only` and `/exclude` cannot be used together.


🟢 EXCLUDING SPECIFIC PROTOCOLS (GLOBAL)
---------------------------------------
   ⚙️ Command:
       Net_Protocols_Test.bat /site google.com /exclude ip4 ip6

   📖 Description:
       - Tests everything except IPv4 and IPv6 protocols.
       - ⚠️ `/only` and `/exclude` cannot be used together.


🟢 INCLUDING OR EXCLUDING PROTOCOLS FOR SPECIFIC SITES
---------------------------------------
   ⚙️ Command:
       Net_Protocols_Test.bat /site google.com+++ip4+++ip6 microsoft.com yahoo.com /exclude ip4 ip6

   📖 Description:
       - IPv4 and IPv6 are included **only for google.com** (due to `+++ip4+++ip6`).
       - IPv4 and IPv6 are excluded for microsoft.com and yahoo.com (global `/exclude`).
       - Specific rules (like `+++`) **override global rules**.


🟢 OVERRIDING GLOBAL RULES FOR SPECIFIC SITES
---------------------------------------
   ⚙️ Command:
       Net_Protocols_Test.bat /site google.com---ip4+++dns microsoft.com /only ip4 ip6

   📖 Description:
       - For `google.com`:
           * IPv4 is excluded (`---ip4`).
           * DNS is included (`+++dns`), overriding the global `/only ip4 ip6`.
       - For `microsoft.com`:
           * Only IPv4 and IPv6 are tested (global `/only ip4 ip6`).


🟢 DEBUGGING AND NO-PAUSE MODE
---------------------------------------
   ⚙️ Command:
       Net_Protocols_Test.bat /site google.com /nodebug /nopause

   📖 Description:
       - Disables debug output for failed tests.
       - Disables pause at the end of the script.
```

---

## Outputs

- **Symbols in the table:**
  - `/` : Test in progress
  - `>` : Test skipped
  - `OK` : Test passed
  - `KO` : Test failed

- Debug files for failed tests are saved in the output directory.

---
