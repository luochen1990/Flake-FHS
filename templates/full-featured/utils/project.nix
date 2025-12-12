{
  lib,

  # Import our own string utilities
  string,
}:

{
  # Project-specific utilities

  # Generate project version string
  generateVersion =
    let
      # Use current date as version (simplified)
      date = lib.substring 0 8 (toString builtins.currentTime);
      hash = string.randomString 6;
    in
    "0.1.0-${date}-${hash}";

  # Validate project name
  isValidProjectName = name:
    let
      # Project names should be lowercase, alphanumeric with hyphens
      pattern = "^[a-z][a-z0-9-]*$";
    in
    builtins.match pattern name != null;

  # Generate default description
  defaultDescription = projectName:
    "A Flake FHS project called ${projectName}";

  # Create project metadata
  createMetadata = projectName: extraAttrs:
    {
      name = projectName;
      version = generateVersion;
      description = defaultDescription projectName;
      created = toString builtins.currentTime;
    } // extraAttrs;
}