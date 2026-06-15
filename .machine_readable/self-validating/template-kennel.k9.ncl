K9!
# SPDX-License-Identifier: MPL-2.0
# K9 Kennel-level template: Pure data configuration
# Security Level: Kennel (data-only, no execution)
# No signature required - safe for any use

{
  pedigree = {
    schema_version = "1.0.0",
    component_type = "build-config",
    security = {
      leash = 'Kennel,
      trust_level = "data-only",
      allow_network = false,
      allow_filesystem_write = false,
      allow_subprocess = false,
    },
    metadata = {
      # Real name — required by K9 pedigree validator
      name = "template-kennel",
      version = "1.0.0",
      description = "Kennel-level (pure data) template for Cliometrics.jl K9 components",
      author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    },
  },

  # Your configuration data here
  config = {
    # Example: Pure data values
    setting_1 = "value",
    setting_2 = 42,
    setting_3 = true,

    nested = {
      key = "value",
    },

    list = [
      "item1",
      "item2",
    ],
  },

  # Optional: Export format specification
  export = {
    format = "json",  # or "yaml", "toml"
    destination = "output.json",
  },
}

# Usage:
# 1. Fill in TODO items above
# 2. Add your configuration data to config = { ... }
# 3. Validate: nickel typecheck your-file.k9.ncl
# 4. Export: nickel export your-file.k9.ncl > output.json
