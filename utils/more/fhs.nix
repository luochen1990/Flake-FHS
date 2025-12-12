# Flake FHS core implementation
# mkFlake function that auto-generates flake outputs from directory structure

{ lib }:

let
  utils = (((import ../utils.nix).prepareUtils ./../../utils).more { inherit lib; });
in
{
  # Main mkFlake function
  mkFlake =
    {
      self,
      lib,
      nixpkgs,
      inputs ? { },
      root ? [ ./. ],
      supportedSystems ? lib.systems.flakeExposed,
      nixpkgsConfig ? {
        allowUnfree = true;
      },
    }:
    let
      roots = root;

      # Define utils once and reuse throughout

      inherit (utils)
        unionFor
        dict
        for
        concatMap
        ;

      # Helper functions
      systemContext' = selfArg: system: rec {
        inherit system inputs utils;
        pkgs = (
          import nixpkgs {
            inherit system;
            config = nixpkgsConfig;
          }
        );
        lib = pkgs.lib;
        specialArgs = {
          self = selfArg;
          inherit
            system
            pkgs
            inputs
            utils
            roots
            ;
        };
      };

      eachSystem =
        f:
        dict supportedSystems (
          system:
          let
            context = systemContext' self system;
          in
          f context
        );

      # Updated component discovery that respects multiple roots
      discoverComponents' =
        componentType:
        let
          # Collect components from all roots as a flat list
          allComponents = concatMap (
            root:
            let
              componentPath = root + "/${componentType}";
            in
            if builtins.pathExists componentPath then
              for (utils.lsDirs componentPath) (name: {
                inherit name root;
                path = componentPath + "/${name}";
              })
            else
              [ ]
          ) roots;
        in
        allComponents;

      # Package discovery with optional default.nix control
      buildPackages' =
        context:
        let
          components = discoverComponents' "pkgs";
          # Check if any pkgs/default.nix exists in roots
          hasDefault = builtins.any (root: builtins.pathExists (root + "/pkgs/default.nix")) roots;
        in
        if hasDefault then
          # Use default.nix to control package visibility
          let
            defaultPkgs = concatMap (
              root:
              let
                defaultPath = root + "/pkgs/default.nix";
              in
              if builtins.pathExists defaultPath then
                let
                  result = import defaultPath context;
                in
                if builtins.isAttrs result then [ result ] else [ ]
              else
                [ ]
            ) roots;
          in
          # Merge all package sets from default.nix files
          builtins.foldl' (acc: pkgs: acc // pkgs) { } defaultPkgs
        else
          # Auto-discover all packages
          dict components (
            name:
            { path, ... }:
            {
              "${name}" = context.pkgs.callPackage (path + "/package.nix") { };
            }
          );

    in
    {
      # Generate all flake outputs
      packages = eachSystem (context: buildPackages' context);

      devShells = eachSystem (
        context:
        let
          components = discoverComponents' "shells";
        in
        if components == [ ] then
          { }
        else
          builtins.foldl' (
            acc: comp:
            acc
            // {
              "${comp.name}" = import comp.path context;
            }
          ) { } components
      );

      apps = eachSystem (
        context:
        let
          components = discoverComponents' "apps";
        in
        if components == [ ] then
          { }
        else
          builtins.foldl' (
            acc: comp:
            acc
            // {
              "${comp.name}" = import comp.path context;
            }
          ) { } components
      );

      nixosModules =
        let
          components = discoverComponents' "modules";
        in
        let
          componentList = components;
        in
        builtins.foldl' (
          acc: comp:
          acc
          // {
            "${comp.name}" = import comp.path;
          }
        ) { } componentList
        // {
          default =
            let
              context = systemContext' self "x86_64-linux";
            in
            unionFor components ({ name, path, ... }: import path);
        };

      nixosConfigurations =
        let
          components = discoverComponents' "profiles";
          context = systemContext' self "x86_64-linux";
          modulesList =
            let
              moduleComponents = discoverComponents' "modules";
            in
            builtins.foldl' (
              acc: comp:
              acc
              ++ [
                import
                comp.path
              ]
            ) [ ] moduleComponents;
        in
        let
          profileList = components;
        in
        builtins.foldl' (
          acc: comp:
          acc
          // {
            "${comp.name}" = context.pkgs.lib.nixosSystem {
              system = "x86_64-linux";
              specialArgs = context.specialArgs // {
                name = comp.name;
              };
              modules = [ (comp.path + "/configuration.nix") ] ++ modulesList;
            };
          }
        ) { } profileList;

      checks = eachSystem (
        context:
        let
          # First try to find check files (like packages)
          checkFiles = concatMap (
            root:
            let
              checksPath = root + "/checks";
            in
            if builtins.pathExists checksPath then
              for (utils.lsFiles checksPath) (name:
                let
                  checkPath = checksPath + "/${name}";
                in
                if builtins.match ".*\\.nix$" name != null && name != "default.nix" then {
                  # Remove .nix suffix for attribute name
                  name = builtins.substring 0 (builtins.stringLength name - 4) name;
                  path = checkPath;
                } else null
              )
            else
              [ ]
          ) roots;

          # Filter out nulls
          validCheckFiles = builtins.filter (x: x != null) checkFiles;

          # Debug info - create a dummy check to show what we found
          debugInfo = {
            roots = roots;
            checkFiles = checkFiles;
            validCheckFiles = validCheckFiles;
          };

          # Also check for directory-based checks (for backward compatibility)
          directoryChecks = discoverComponents' "checks";
        in
        if validCheckFiles != [ ] then
          # Use file-based checks
          builtins.listToAttrs (map (item: {
            name = item.name;
            value = import item.path context;
          }) validCheckFiles)
        else if directoryChecks != [ ] then
          # Use directory-based checks
          builtins.foldl' (
            acc: comp:
            acc
            // {
              "${comp.name}" = import comp.path context;
            }
          ) { } directoryChecks
        else
          { }
      );

      lib =
        let
          context = systemContext' self "x86_64-linux";

          # Find actual utils directories (not subdirectories)
          # This should find utils/ directories directly under each root
          findUtilsRoots = map (root: {
            name = "utils";
            path = root + "/utils";
          }) (builtins.filter (root: builtins.pathExists (root + "/utils")) roots);

          # Process each utils directory with prepareUtils.more.more
          processUtilsDir =
            comp:
            let
              utilsResult = (
                (((import ../utils.nix).prepareUtils comp.path).more { lib = context.lib; }).more {
                  pkgs = context.pkgs;
                }
              );
            in
            utilsResult;

          # Merge all processed utils from all utils directories
          mergedUtils = builtins.foldl' (acc: comp: acc // (processUtilsDir comp)) { } findUtilsRoots;
        in
        mergedUtils;

      templates =
        let
          readTemplatesFromRoot =
            root:
            let
              templatePath = root + "/templates";
            in
            if builtins.pathExists templatePath then
              for (utils.lsDirs templatePath) (
                name:
                let
                  fullPath = templatePath + "/${name}";
                  flakePath = fullPath + "/flake.nix";
                  hasFlake = builtins.pathExists flakePath;
                  description =
                    if hasFlake then (import flakePath).description or "Template: ${name}" else "Template: ${name}";
                in
                {
                  inherit name;
                  value = {
                    path = fullPath;
                    inherit description;
                  };
                }
              )
            else
              [ ];

          allTemplateLists = map readTemplatesFromRoot roots;
          allTemplates = concatMap (x: x) allTemplateLists;
        in
        builtins.listToAttrs allTemplates;

      # Auto-generated overlay for packages
      overlays.default =
        final: prev:
        let
          context = {
            pkgs = final;
            inherit (final) lib;
            inherit utils;
          };
        in
        buildPackages' context;

      # Formatter
      formatter = eachSystem ({ pkgs, ... }: pkgs.nixfmt-tree);
    };

}
