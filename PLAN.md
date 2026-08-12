# ArtifactManager implementation plan

## Scope and requirements

ArtifactManager will provide a shared, verified way for GAP packages to use
large optional data without including it in package archives. This plan is
adapted from [GAP issue #4285](https://github.com/gap-system/gap/issues/4285)
and its discussion.

The system must provide the following behaviour:

- Package authors describe many small, independently retrievable artifacts;
  requesting one table or data file must not download an entire database.
- A package can retrieve an artifact into the managed cache on demand, or
  download it directly to a caller-supplied target without entering that
  cache.
- Every managed database has a configurable storage location. The default may
  be beneath `GAPInfo.UserGapRoot`, but it must work in multi-user
  installations and never write into a package directory.
- Downloads use HTTPS, redirects, retries, and multiple mirrors through a
  centrally maintained and extensible download mechanism.
- Every download is validated with SHA-256 before use. GAP 4.12 or newer
  provides `HexSHA256`, so no optional compiled checksum package is needed.
- Users can inspect downloaded data and disk usage uniformly, explicitly
  remove data, and garbage-collect data no longer referenced by an installed
  package.
- The implementation is platform-independent; platform selection is out of
  scope.

The first release supports `.tar.gz` data trees only. A compressed archive is
one artifact, not a substitute for publishing a whole database as a single
download. Individual-file artifacts and archive-as-directory access for very
many small files are later extensions.

## Manifest contract

Each client package places an `Artifacts.g` in its root. It is a declarative
GAP source file that returns a list of records. ArtifactManager reads it with
`ReadAsFunction(...)()` and validates that the result contains data-only
records with the schema below. This is acceptable because the containing GAP
package is already executable and trusted; validation still prevents accidental
use of arbitrary manifest values.

Artifact names are fine-grained and stable; a data update creates a new tree
hash. `tree_sha256` identifies the canonical extracted data tree. Each
download record has its own `sha256`, because different `.tar.gz` byte streams
can unpack to the same artifact.

```gap
return [
  rec(
    name := "brent-table-1000",
    tree_sha256 := "<64 lowercase hexadecimal characters>",
    lazy := true,
    downloads := [
      rec(
        url := "https://example.org/data/brent-table-1000.tar.gz",
        sha256 := "<SHA-256 of this archive>"
      ),
      rec(
        url := "https://mirror.example.org/data/brent-table-1000.tar.gz",
        sha256 := "<SHA-256 of this archive>"
      )
    ]
  )
];
```

Version 1 requires exactly the `name`, `tree_sha256`, `lazy`, and `downloads`
fields on each artifact record; each download record requires exactly `url`
and `sha256`. Missing fields, unknown fields, duplicate names, malformed URLs,
and invalid hashes are errors.
`lazy` is required and must be `true` in the first implementation. Support for
`lazy := false` and eager bulk installation is added later. All declared
downloads must be `.tar.gz` archives.

The managed cache retains the verified archive and its extracted data tree.
`ArtifactPath` returns the extracted directory; later verification can
recompute the selected archive's SHA-256 and the extracted tree's canonical
SHA-256 hash.

## Public API

All functions below are part of the planned stable API and require GAPDoc
documentation and tests.

| Done | Function | Purpose |
| --- | --- | --- |
| x | `ArtifactMetadata(pkgname, name)` | Resolve and validate one named artifact. |
| x | `ArtifactHash(pkgname, name)` | Return the artifact's expected canonical tree SHA-256 digest. |
|   | `ArtifactStoreDirectory(pkgname)` | Return the configured store directory for this pkgname, creating it when necessary. |
|   | `SetArtifactStoreDirectory(pkgname, dir)` | Set a per-package store directory for the current GAP session after checking that it is usable. |
|   | `ArtifactInstallPath(pkgname, name)` | Return the deterministic managed-cache path without downloading. |
|   | `ArtifactExists(pkgname, name)` | Return whether a verified cached artifact is present. |
|   | `VerifyArtifact(pkgname, name)` | Verify the cached archive's recorded SHA-256 and extracted tree hash. |
|   | `EnsureArtifactInstalled(pkgname, name)` | Fetch a missing artifact into its managed store, verify it, and return its path. |
|   | `ArtifactPath(pkgname, name)` | Standard lazy entry point: ensure the artifact is cached, then return its unpacked directory path. |
|   | `ArtifactFilePath(pkgname, name)` | Later milestone: ensure an individual-file artifact is cached, then return its local file path. |
|   | `FetchArtifact(pkgname, name, destination)` | Fetch, unpack, and verify an artifact at `destination` without retaining it in the managed cache. |
|   | `EnsureAllArtifactsInstalled(pkgname[, includeLazy])` | Install all non-lazy artifacts, or all artifacts when requested, and return a report. |
| x | `ListArtifacts(pkgname)` | Return declared validated metadata; cache fields are added later. |
|   | `ArtifactStorageInfo([pkgname])` | Report managed stores and their artifact sizes; without an argument, report all stores known to this GAP session. |
|   | `RemoveArtifact(pkgname, name)` | Remove one cached artifact after resolving it and return the reclaimed size. |
|   | `GarbageCollectArtifacts()` | Remove stale, unreferenced cached artifacts and return a dry-run-capable report. |

`pkgname` is always the first argument and is mandatory. It is the GAP package
name that provides the artifact manifest. The current reader resolves it to the
package's root `Artifacts.g` file.

## Internal function inventory

Keep internal functions prefixed `ArtifactManager_`; test them through public
behaviour where feasible.

| Done | Function | Responsibility |
| --- | --- | --- |
|   | `ArtifactManager_ResolveManifest` | Normalize package-directory or manifest input to an absolute manifest filename. |
|   | `ArtifactManager_ManifestId` | Derive a stable per-database identifier from the client package and manifest path. |
| x | `ArtifactManager_ManifestFilename` | Resolve a package name to its root `Artifacts.g` filename. |
| x | `ArtifactManager_ReadManifest` | Evaluate a trusted `Artifacts.g` file and return its result. |
| x | `ArtifactManager_ValidateManifest` | Validate names, types, artifact hashes, download records, and duplicates. |
| x | `ArtifactManager_ResolveArtifact(pkgname, name, artifacts)` | Return one validated artifact metadata record. |
|   | `ArtifactManager_ResolveStoreDirectory` | Apply per-database configuration, environment/default policy, recursive creation, and writability checks. |
|   | `ArtifactManager_CreateWritableDirectory` | Create missing parent directories and give actionable permission errors. |
|   | `ArtifactManager_DownloadMethod` | Select an available registered HTTPS download method. |
|   | `ArtifactManager_DownloadToFile` | Download one URL to a private target with redirect, timeout, and retry settings. |
|   | `ArtifactManager_VerifyDownloadSHA256` | Compare a downloaded archive with its selected download record. |
|   | `ArtifactManager_ExtractArchive` | Extract a supported archive into a private staging directory. |
|   | `ArtifactManager_ValidateArchiveTree` | Reject absolute paths, `..` traversal, escaping links, and unsupported file types. |
|   | `ArtifactManager_TreeSHA256` | Calculate the documented canonical SHA-256 digest of an extracted tree. |
|   | `ArtifactManager_InstallationLock` | Acquire and release a per-artifact lock for concurrent GAP sessions. |
|   | `ArtifactManager_InstallFromMirrors` | Retry mirrors in order, preserve errors, and clean temporary output. |
|   | `ArtifactManager_CommitArtifact` | Atomically promote a verified staged artifact into the store. |
|   | `ArtifactManager_RecordReference` | Record a package/manifest reference to an installed artifact for inspection and GC. |
|   | `ArtifactManager_ScanReferences` | Discover live references from installed packages and persisted records. |
|   | `ArtifactManager_ArtifactSize` | Calculate an installed artifact tree's disk usage. |
| x | `ArtifactManager_Error` | Report artifact, manifest, operation, URL, and remediation details. |

## Sequential implementation steps

### 1. Build the manifest reader and artifact resolution API

- Load the trusted declarative `Artifacts.g` file with `ReadAsFunction(...)()`
  and require it to return a list of records with the documented fields only.
  Preserve filename context in validation errors.
- Reject an artifact declaration that groups unrelated data solely for bulk
  download. Document naming guidance for per-table and per-file artifacts.
- Add manifest fixtures for valid archive entries, invalid hashes, malformed
  download records, duplicate names, missing downloads, and multiple mirrors.
- Implement resolution without network or filesystem writes.

Functions added: `ArtifactMetadata`, `ArtifactHash`, `ListArtifacts`,
`ArtifactManager_ManifestFilename`, `ArtifactManager_ReadManifest`,
`ArtifactManager_ValidateManifest`, `ArtifactManager_ResolveArtifact`, and
`ArtifactManager_Error`.

### 2. Define the package contract and low-level boundaries

- Replace package-template documentation and the placeholder API with the
  scope above, including an example `Artifacts.g` that names a small unit
  of data.
- Confirm `utils` provides the maintained extensible `Download` mechanism;
  declare the minimum compatible version in `NeededOtherPackages` rather than
  duplicating HTTP, redirect, and TLS logic in this package.
- Require GAP `>= 4.12` for `HexSHA256`, unless maintaining a compatibility
  implementation has a concrete user need.
- Specify the canonical tree-hash encoding before implementation: sorted
  relative paths, entry types, permitted mode bits, and file bytes. Version 1
  rejects symbolic links and special files, avoiding ambiguous hash semantics.
- Specify store precedence: per-database session override, a documented
  environment/user preference override, then a directory beneath
  `GAPInfo.UserGapRoot`. Document how a shared multi-user installation sets a
  database-specific writable location.
- Decide the persistent reference-record format used by listing and GC before
  any artifact is written.

Functions added: `ArtifactManager_ResolveManifest`,
`ArtifactManager_ManifestId`, `ArtifactManager_ResolveStoreDirectory`,
`ArtifactManager_CreateWritableDirectory`, `ArtifactStoreDirectory`, and
`SetArtifactStoreDirectory`.

### 3. Add reusable verified retrieval primitives

- Integrate with `utils` download methods so callers and other packages can
  add a method without editing ArtifactManager. Test method selection, HTTPS,
  redirects, retries, timeouts, and unavailable-method errors.
- Download each mirror into a private temporary file and run `HexSHA256`
  against that mirror's download record before any artifact becomes visible.
  A checksum mismatch must try the next mirror and leave no retained output.
- Implement `FetchArtifact(pkgname, name, destination)` as the no-cache
  path. It verifies the selected download, extracts it, verifies the tree,
  and writes only to the caller's explicit destination, never the configured
  artifact store.
- Add an end-to-end local HTTP fixture for mirror fallback and failures; avoid
  requiring public-network access in the ordinary test suite.

Functions added: `FetchArtifact`, `ArtifactManager_DownloadMethod`,
`ArtifactManager_DownloadToFile`, `ArtifactManager_VerifyDownloadSHA256`, and
`ArtifactManager_InstallFromMirrors`.

### 4. Implement the managed lazy cache

- Use the canonical tree SHA-256 digest in the cache path so different
  tarballs containing the same data are shared within a database store.
- Extract each `.tar.gz` archive only in a private staging directory after
  archive path and link validation.
- Retain the verified archive beside the extracted tree so later verification
  can recompute its selected download SHA-256 without network access.
- Compute and compare the canonical tree SHA-256 before committing the staged
  extraction, then recompute it in `VerifyArtifact` when explicitly requested.
- Guard an installation with a per-digest lock, re-check after acquiring it,
  and atomically promote the fully verified result. Concurrent installers must
  converge on one valid artifact.
- Make `ArtifactExists` and `VerifyArtifact` treat a corrupt cache entry as
  absent; `ArtifactPath` must re-install it rather than returning bad data.

Functions added: `ArtifactInstallPath`, `ArtifactExists`, `VerifyArtifact`,
`EnsureArtifactInstalled`, `ArtifactPath`,
`ArtifactManager_ExtractArchive`, `ArtifactManager_ValidateArchiveTree`,
`ArtifactManager_TreeSHA256`, `ArtifactManager_InstallationLock`, and
`ArtifactManager_CommitArtifact`.

### 5. Add eager installation and artifact lifecycle records

- Implement bulk installation, skipping lazy entries by default and reporting
  installed, already-present, skipped, and failed names distinctly.
- Record the manifest identity, artifact name, checksum, store, install time,
  and size whenever an artifact is installed. Update records only after the
  atomic commit succeeds.
- Ensure artifact updates are additive: a new checksum never overwrites a
  cached earlier revision that another installed package version may still
  reference.
- Test first install, cache reuse without network, lazy skipping, eager
  installation, interrupted download cleanup, and concurrent installation.

Functions added: `EnsureAllArtifactsInstalled`,
`ArtifactManager_RecordReference`, and `ArtifactManager_ArtifactSize`.

### 6. Deliver inspection, removal, and garbage collection

- Implement per-manifest listing and global storage reporting with artifact
  name, owning manifest/package, path, verification status, and disk usage.
- Implement explicit single-artifact removal; it must remove only the resolved
  cache entry and its reference record, never a package directory.
- Implement GC with a mandatory dry-run mode, then an explicit execution
  mode. It may delete an artifact only when no installed package manifest or
  valid reference record still points to its digest.
- Add tests for stale records, removed package copies, shared artifacts,
  corrupt records, permission failures, and accurate reclaimed-size reports.

Functions added: `ArtifactStorageInfo`, `RemoveArtifact`,
`GarbageCollectArtifacts`, `ArtifactManager_ScanReferences`.

### 7. Harden, document, and release version 1

- Add security regression tests for path traversal, symbolic-link escapes,
  malformed archives, checksum mismatches, stale locks, and unreadable or
  unwritable stores.
- Explain the security model: checksums give integrity, HTTPS protects
  transport, and a manifest checksum update is a data release decision.
- Document migrations for AtlasRep-style data directories and the other
  candidate packages identified in the issue: `simpcomp`, `transgrp`,
  `tomlib`, `unitlib`, `FactInt`, `primgrp`, and `perfgrp`.
- Generate the GAP manual and test every declared GAP/package dependency in
  CI. No ordinary test may require external network access.

### 8. Add individual-file artifacts

- Extend `Artifacts.g` with an explicit artifact kind, retaining `.tar.gz` as
  the default so existing manifests remain valid.
- Implement verified caching for individual files without extraction, with
  `ArtifactFilePath(pkgname, name)` returning the local file. Keep
  `ArtifactPath` as the directory-returning API for unpacked `.tar.gz`
  artifacts.
- For a file artifact, use an artifact-level `sha256` of its contents and
  retain per-URL download records whose SHA-256 values must equal that hash.
- Extend `FetchArtifact` and cache verification to handle both artifact kinds,
  and add fixtures for file-only downloads and mirror fallback.

The single-file manifest shape will be:

```gap
rec(
  name := "brent-table-1000",
  kind := "file",
  sha256 := "<SHA-256 of the file contents>",
  lazy := true,
  downloads := [
    rec(
      url := "https://example.org/data/brent-table-1000",
      sha256 := "<same SHA-256 value>"
    ),
    rec(
      url := "https://mirror.example.org/data/brent-table-1000",
      sha256 := "<same SHA-256 value>"
    )
  ]
)
```

Unlike a tarball, a file has no distinct unpacked tree: its artifact hash is
the SHA-256 of its bytes. Repeating that value per download is intentional. It
keeps download validation uniform and rejects a misconfigured mirror before
the managed cache is changed.

Functions added: `ArtifactFilePath`.

### 9. Later extensions

- Provide read-only archive-as-directory access for workloads with extremely
  many small files, only after defining filename, lookup, and resource-lifetime
  semantics that are safe for GAP callers.
- Add optional author tooling for creating and publishing artifacts, separate
  from the runtime API: `CreateArtifact`, `ArchiveArtifact`, `BindArtifact`,
  and `UnbindArtifact`.
- Add cache quotas or age-based cleanup policies only after the explicit GC
  behaviour is proven and remains conservative by default.

## Definition of done for version 1

A client GAP package can declare small optional `.tar.gz` data trees in
`Artifacts.g`, use `ArtifactPath` to retrieve only the required item into a configured
per-database cache, use `FetchArtifact` when it must avoid that cache, and
trust SHA-256 verification in both cases. Users can see the data's disk usage,
remove an item, and dry-run or perform garbage collection without risking
package source directories or still-referenced data.
